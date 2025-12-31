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

# UPDATED TO WORKING 22.04.5 URL
ISO_NAME="ubuntu-22.04.5-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# 1. ISO READINESS (The "Zero Byte" Killer)
EXPECTED_ISO_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_ISO_DIR"
ISO_PATH="$EXPECTED_ISO_DIR/$ISO_NAME"

echo "▶ Checking ISO status..."

# If file is 0 bytes, it was a failed download. Delete it.
if [ -f "$ISO_PATH" ] && [ ! -s "$ISO_PATH" ]; then
    echo "× Detected 0-byte file (404 error). Deleting..."
    rm "$ISO_PATH"
fi

# Download if missing
if [ ! -f "$ISO_PATH" ]; then
    echo "▶ Downloading $ISO_NAME..."
    if ! wget -q --show-progress -O "$ISO_PATH" "$ISO_URL"; then
        echo "× ERROR: Download failed. The URL might have changed again."
        echo "Check: https://releases.ubuntu.com/22.04/"
        rm -f "$ISO_PATH"
        exit 1
    fi
fi
echo "✔ ISO verified: $(du -h "$ISO_PATH" | cut -f1)"

# 2. VM CREATION
VMID=$(pvesh get /cluster/nextid)
echo "▶ Creating VM $VMID..."

qm create $VMID --name "$VM_NAME" --cores "$CORES" --memory "$MEMORY" \
    --net0 virtio,bridge="$BRIDGE" --scsihw virtio-scsi-pci --onboot 1

# THE "16G" PARSE FIX
qm set $VMID --scsi0 "$STORAGE:$DISK_SIZE"

# THE "VOLUME DOES NOT EXIST" FIX
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"
qm set $VMID --boot order="ide2;scsi0"

# 3. START & WAIT
qm start $VMID
echo "------------------------------------------------------------"
echo "VM $VMID is now running."
echo "1. Complete the Ubuntu install in the Proxmox Console."
echo "2. REBOOT when finished."
echo "------------------------------------------------------------"
read -p "Press [Enter] after the VM has rebooted and is ready for SSH..."

# 4. SSH & DEPLOY
read -p "Enter VM IP Address: " VM_IP
SSH_USER="ubuntu"

echo -n "▶ Waiting for SSH on $VM_IP ."
until nc -z -w3 "$VM_IP" 22 >/dev/null 2>&1; do echo -n "."; sleep 5; done
echo -e "\n✔ Connected!"

# Credentials
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

# 5. CLEANUP
qm set $VMID --ide2 none,media=cdrom
qm set $VMID --boot order="scsi0"

echo "✔ Deployment complete: http://$VM_IP"