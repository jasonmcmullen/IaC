#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # Storage for the VM Hard Drive
ISO_STORAGE="local"       # Storage for the ISO file
BRIDGE="vmbr0"
DISK="16"                 # GB
MEMORY=4096               
CORES=2
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# Ensure Proxmox CLI is available
command -v qm >/dev/null || { echo "ERROR: Must run on Proxmox host."; exit 1; }

# 1. VALIDATE & PREPARE ISO STORAGE
# Get the actual mount point for the ISO storage (usually /var/lib/vz)
ISO_BASE_PATH=$(pvesm parse-path "$ISO_STORAGE:iso/test.iso" 2>/dev/null | grep "path:" | awk '{print $2}' | xargs dirname | xargs dirname || echo "/var/lib/vz/template/iso")
mkdir -p "$ISO_BASE_PATH"

# Ensure the storage is configured for ISOs in Proxmox
pvesm set "$ISO_STORAGE" --content iso 2>/dev/null || true

# Download ISO if missing
ISO_DEST="$ISO_BASE_PATH/$ISO_NAME"
if [ ! -f "$ISO_DEST" ]; then
    echo "▶ ISO not found at $ISO_DEST. Downloading..."
    wget -O "$ISO_DEST" "$ISO_URL"
fi

# 2. CREATE VM
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

qm create $VMID \
    --name "$VM_NAME" \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --onboot 1

# 3. CONFIGURE DISKS
echo "▶ Allocating $DISK GB disk on $STORAGE..."
# Format 'storage:size' (number only) creates a new LVM volume
qm set $VMID --scsi0 "$STORAGE:$DISK"

echo "▶ Attaching ISO from $ISO_STORAGE..."
# Format 'storage:iso/filename' is required by Proxmox
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"

# Set boot order: CD-ROM first, then Disk
qm set $VMID --boot order="ide2;scsi0"

# 4. START & DEPLOY
qm start $VMID
echo "▶ VM $VMID started. Please complete the OS install in the console."

# Credential Generation
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

echo "------------------------------------------------------------"
read -p "Enter VM IP address after installation: " VM_IP
SSH_USER="ubuntu"

echo "▶ Deploying stack to $VM_IP..."
until nc -zvw3 "$VM_IP" 22 2>/dev/null; do
    echo "Waiting for SSH..."
    sleep 5
done

ssh -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" bash -s <<EOF
set -e
sudo apt update && sudo apt install -y git curl

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker \$USER

# Deploy IaC
sudo mkdir -p /opt/IaC
sudo chown \$USER:\$USER /opt/IaC
git clone https://github.com/jasonmcmullen/IaC.git /opt/IaC
cd /opt/IaC

echo "ADMIN_PASSWORD=${ADMIN_PASS}" > .env
echo "API_TOKEN=${API_TOKEN}" >> .env

sudo docker compose up -d
EOF

echo "✔ Deployment complete: http://$VM_IP"
echo "✔ Password: $ADMIN_PASS"