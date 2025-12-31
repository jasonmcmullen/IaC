#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # VM Disk Storage
ISO_STORAGE="local"       # ISO Storage ID (usually 'local')
BRIDGE="vmbr0"
DISK_SIZE="16"            # GB (Integer only)
MEMORY="4096"
CORES="2"
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# 1. ISO VALIDATION & READINESS
EXPECTED_ISO_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_ISO_DIR"
ISO_PATH="$EXPECTED_ISO_DIR/$ISO_NAME"

echo "▶ Validating ISO file..."

# FIX: If file is 0 bytes or missing, download it
if [ -f "$ISO_PATH" ] && [ ! -s "$ISO_PATH" ]; then
    echo "× Found 0-byte ISO file. Deleting and re-downloading..."
    rm "$ISO_PATH"
fi

if [ ! -f "$ISO_PATH" ]; then
    echo "▶ ISO not found. Downloading (this may take a few minutes)..."
    wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"
    # Double check after download
    if [ ! -s "$ISO_PATH" ]; then
        echo "× ERROR: Download failed or resulted in 0-byte file. Check your internet connection."
        exit 1
    fi
fi
echo "✔ ISO ready: $(du -h "$ISO_PATH" | cut -f1)"

# 2. VM PROVISIONING
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

echo "▶ Creating VM container..."
qm create $VMID --name "$VM_NAME" --cores "$CORES" --memory "$MEMORY" \
    --net0 virtio,bridge="$BRIDGE" --scsihw virtio-scsi-pci --onboot 1

# THE "16G" PARSE FIX
echo "▶ Allocating $DISK_SIZE GB disk on $STORAGE..."
qm set $VMID --scsi0 "$STORAGE:$DISK_SIZE"

echo "▶ Mounting ISO and setting boot order..."
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"
qm set $VMID --boot order="ide2;scsi0"

# 3. START & WAIT FOR INSTALL
echo "▶ Starting VM $VMID..."
qm start $VMID

echo "------------------------------------------------------------"
echo "!! ACTION REQUIRED !!"
echo "1. Open the Proxmox Console for VM $VMID."
echo "2. Complete the Ubuntu installation manually."
echo "3. REBOOT the VM after installation is finished."
echo "------------------------------------------------------------"
read -p "Press [Enter] ONLY after you have finished the OS install and the VM has rebooted..."

# 4. SSH AVAILABILITY CHECK
read -p "Enter the VM's IP address: " VM_IP
SSH_USER="ubuntu"

echo -n "▶ Waiting for SSH on $VM_IP ."
until nc -z -w3 "$VM_IP" 22 >/dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo -e "\n✔ Connected! Starting IaC stack deployment..."

# 5. REMOTE DEPLOYMENT
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

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

# 6. POST-INSTALL HARDWARE CLEANUP
echo "▶ Ejecting installer ISO and setting boot to Disk..."
qm set $VMID --ide2 none,media=cdrom
qm set $VMID --boot order="scsi0"

echo "------------------------------------------------------------"
echo "✔ IaC Deployment Complete!"
echo "✔ URL: http://$VM_IP"
echo "✔ ADMIN_PASS: $ADMIN_PASS"
echo "✔ API_TOKEN: $API_TOKEN"
echo "------------------------------------------------------------"