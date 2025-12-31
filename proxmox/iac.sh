#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # LVM thin pool for VM disk
BRIDGE="vmbr0"
DISK="16"                 # GB, number only for allocation
MEMORY=4096               # MB
CORES=2
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
ISO_STORAGE_PATH="/var/lib/vz/template/iso"
ISO_STORAGE="local"       # Proxmox ISO storage name
### --------------

# Ensure Proxmox CLI is available
command -v qm >/dev/null || { echo "ERROR: Must run on Proxmox host."; exit 1; }

# Create ISO storage directory if missing
mkdir -p "$ISO_STORAGE_PATH"

# Download ISO if missing
ISO_PATH="$ISO_STORAGE_PATH/$ISO_NAME"
if [ ! -f "$ISO_PATH" ]; then
    echo "▶ ISO not found. Downloading $ISO_NAME..."
    wget -O "$ISO_PATH" "$ISO_URL"
fi

# Select next free VMID
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

# 1. Create VM container
# We don't define the disk here to avoid the parsing error
qm create $VMID \
    --name "$VM_NAME" \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --onboot 1

# 2. FIX: Allocate the primary hard drive
# Using 'storage:size' tells Proxmox to create a NEW volume
echo "▶ Allocating $DISK GB disk on $STORAGE..."
qm set $VMID --scsi0 "$STORAGE:$DISK"

# 3. FIX: Attach the ISO as a CD-ROM
# ISOs are referenced as 'storage:iso/filename'
echo "▶ Attaching ISO as CD-ROM..."
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"

# 4. Set boot order to boot from CD-ROM (ide2) first, then HDD (scsi0)
qm set $VMID --boot order="ide2;scsi0"

# Start VM
qm start $VMID
echo "▶ VM $VMID started."
echo "▶ ACTION REQUIRED: Open the Proxmox Console and complete the Ubuntu installation."

# Generate credentials for IaC
ADMIN_PASS=$(openssl rand -base64 16)
API_TOKEN=$(openssl rand -hex 16)

# Deployment logic
echo "------------------------------------------------------------"
echo "Once installation is complete and the VM has rebooted:"
read -p "Enter VM IP address: " VM_IP
SSH_USER="ubuntu"

echo "▶ Deploying IaC stack to $VM_IP..."

# Wait for SSH to be ready
until nc -zvw3 "$VM_IP" 22; do
    echo "Waiting for SSH to respond on $VM_IP..."
    sleep 5
done

ssh -o StrictHostKeyChecking=no "$SSH_USER@$VM_IP" bash -s <<EOF
set -e
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git

# Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker

# Deploy IaC stack
sudo mkdir -p /opt/IaC
sudo chown \$USER:\$USER /opt/IaC
git clone https://github.com/jasonmcmullen/IaC.git /opt/IaC
cd /opt/IaC

# Write .env
cat > .env <<EOV
ADMIN_PASSWORD=${ADMIN_PASS}
API_TOKEN=${API_TOKEN}
EOV

# Start stack
sudo docker compose up -d
EOF

echo "------------------------------------------------------------"
echo "✔ IaC deployment complete on VM $VM_NAME ($VM_IP)"
echo "✔ URL: http://$VM_IP"
echo "✔ ADMIN_PASSWORD: $ADMIN_PASS"
echo "✔ API_TOKEN: $API_TOKEN"