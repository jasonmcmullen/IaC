#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # Storage for the VM Hard Drive
ISO_STORAGE="local"       # Storage ID where ISOs are kept
BRIDGE="vmbr0"
DISK_SIZE="16"            # GB (Plain number)
MEMORY=4096               
CORES=2
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# 1. PREPARE ISO STORAGE
# Ensure Proxmox recognizes the storage for ISOs
pvesm set "$ISO_STORAGE" --content iso 2>/dev/null || true

# Find where Proxmox actually mounts this storage
ISO_DIR=$(pvesm status -storage "$ISO_STORAGE" | awk 'NR==2 {print $6}')
# Default to common path if detection fails
ISO_DIR=${ISO_DIR:-/var/lib/vz}
ISO_PATH="$ISO_DIR/template/iso/$ISO_NAME"

mkdir -p "$(dirname "$ISO_PATH")"

if [ ! -f "$ISO_PATH" ]; then
    echo "▶ ISO not found. Downloading to $ISO_PATH..."
    wget -O "$ISO_PATH" "$ISO_URL"
fi

# 2. CREATE VM
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

# We create the VM without the disk first to avoid parsing errors
qm create $VMID \
    --name "$VM_NAME" \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --onboot 1

# 3. CONFIGURE DISKS (THE FIX)
# We use the raw size integer. Format is STORAGE:SIZE
echo "▶ Allocating ${DISK_SIZE}GB on $STORAGE..."
qm set $VMID --scsi0 "$STORAGE:$DISK_SIZE"

# Attach ISO - Note: We use the Proxmox volume ID format
echo "▶ Mounting ISO: $ISO_STORAGE:iso/$ISO_NAME"
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"

# Set Boot Order
qm set $VMID --boot order="ide2;scsi0"

# 4. START
qm start $VMID
echo "▶ VM $VMID is running. Complete the install in the Proxmox console."

# --- Deployment Logic ---
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

echo "------------------------------------------------------------"
read -p "Enter VM IP address once installed: " VM_IP
SSH_USER="ubuntu"

echo "▶ Waiting for SSH on $VM_IP..."
until nc -zvw3 "$VM_IP" 22 2>/dev/null; do sleep 5; done

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

echo "✔ Done! http://$VM_IP"