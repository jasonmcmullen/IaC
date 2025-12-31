#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # LVM thin pool for VM disk
BRIDGE="vmbr0"
DISK=16                   # GB (number only)
MEMORY=4096               # MB
CORES=2
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
ISO_STORAGE_PATH="/var/lib/vz/template/iso"
ISO_STORAGE="local"       # Proxmox ISO storage
SSH_KEY=""                # optional
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

# Create VM without disk
qm create $VMID \
    --name $VM_NAME \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --boot c --bootdisk scsi0 \
    --onboot 1

# Create LVM disk
qm disk create $VMID scsi0 $STORAGE --size $DISK

# Attach ISO as CD-ROM
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME",media=cdrom

# Start VM
qm start $VMID
echo "▶ VM $VM_NAME created and started. Complete Ubuntu installation manually or via cloud-init."

# Generate random credentials
ADMIN_PASS=$(openssl rand -base64 16)
API_TOKEN=$(openssl rand -hex 16)

# Deploy IaC stack after VM install
read -p "Enter VM IP address after installation: " VM_IP
SSH_USER="ubuntu"

ssh $SSH_USER@$VM_IP bash -s <<'EOF'
set -e
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git

# Install Docker
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable docker

# Deploy IaC stack
sudo mkdir -p /opt
cd /opt
sudo git clone https://github.com/jasonmcmullen/IaC.git
cd IaC

# Write .env with credentials
cat > .env <<EOV
ADMIN_PASSWORD=${ADMIN_PASS}
API_TOKEN=${API_TOKEN}
EOV

# Start stack
sudo docker compose up -d
EOF

echo "✔ IaC deployment complete on VM $VM_NAME ($VM_IP)"
echo "✔ Credentials: ADMIN_PASSWORD=$ADMIN_PASS, API_TOKEN=$API_TOKEN"
