#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"
ISO_STORAGE="local"
BRIDGE="vmbr0"
DISK_SIZE="16"            
MEMORY="4096"
CORES="2"
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# 1. ISO READINESS VALIDATION
EXPECTED_ISO_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_ISO_DIR"
ISO_PATH="$EXPECTED_ISO_DIR/$ISO_NAME"

echo "▶ Validating ISO Readiness..."

# Check if file exists and has a healthy size (> 1GB)
if [ -f "$ISO_PATH" ]; then
    FILE_SIZE=$(stat -c%s "$ISO_PATH")
    if [ "$FILE_SIZE" -lt 1000000000 ]; then
        echo "× ISO is corrupt or empty (Size: $FILE_SIZE bytes). Deleting..."
        rm "$ISO_PATH"
    else
        echo "✔ ISO is ready and verified."
    fi
fi

if [ ! -f "$ISO_PATH" ]; then
    echo "▶ ISO missing. Downloading now (this may take a few minutes)..."
    wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
    echo "✔ Download complete."
fi

# 2. VM PROVISIONING
VMID=$(pvesh get /cluster/nextid)
echo "▶ Provisioning VMID: $VMID"

qm create $VMID --name "$VM_NAME" --cores "$CORES" --memory "$MEMORY" \
    --net0 virtio,bridge="$BRIDGE" --scsihw virtio-scsi-pci --onboot 1

echo "▶ Allocating $DISK_SIZE GB disk..."
qm set $VMID --scsi0 "$STORAGE:$DISK_SIZE"

echo "▶ Mounting ISO and configuring boot..."
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"
qm set $VMID --boot order="ide2;scsi0"

# 3. INTERACTIVE INSTALLATION PHASE
echo "▶ Starting VM..."
qm start $VMID

echo "------------------------------------------------------------"
echo "STEP 1: Open the Proxmox Console for VM $VMID."
echo "STEP 2: Install Ubuntu. (Tip: Use the default 'ubuntu' user)."
echo "STEP 3: Once finished, the VM will reboot."
echo "------------------------------------------------------------"
read -p "Press [Enter] once the OS is installed and you are at the login screen..."

# 4. REMOTE DEPLOYMENT (SSH WAIT)
read -p "Enter the VM's IP address: " VM_IP
SSH_USER="ubuntu"

echo -n "▶ Waiting for SSH service on $VM_IP ."
until nc -z -w3 "$VM_IP" 22 >/dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo -e "\n✔ Connected!"

# 5. STACK DEPLOYMENT
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

echo "▶ Running remote IaC deployment..."
ssh -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" bash -s <<EOF
set -e
sudo apt update && sudo apt install -y git curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker \$USER
sudo mkdir -p /opt/IaC && sudo chown \$USER:\$USER /opt/IaC
git clone https://github.com/jasonmcmullen/IaC.git /opt/IaC
cd /opt/IaC
echo "ADMIN_PASSWORD=${ADMIN_PASS}" > .env
echo "API_TOKEN=${API_TOKEN}" >> .env
sudo docker compose up -d
EOF

# 6. POST-DEPLOYMENT CLEANUP
echo "▶ Cleaning up VM hardware (removing installer ISO)..."
qm set $VMID --ide2 none,media=cdrom
qm set $VMID --boot order="scsi0"

echo "------------------------------------------------------------"
echo "✔ COMPLETE!"
echo "✔ URL: http://$VM_IP"
echo "✔ ADMIN_PASS: $ADMIN_PASS"
echo "✔ API_TOKEN: $API_TOKEN"
echo "------------------------------------------------------------"