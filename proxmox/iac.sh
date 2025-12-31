#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"
BRIDGE="vmbr0"
DISK=16      # GB
MEMORY=4096  # MB
CORES=2
ISO_TEMPLATE="local:iso/ubuntu-22.04.3-live-server-amd64.iso"
SSH_KEY=""   # optional: insert your public key here
### --------------

# Ensure running on Proxmox
command -v qm >/dev/null || { echo "ERROR: Must run on Proxmox host."; exit 1; }

# Select next free VMID
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

# Create VM with correct disk allocation
qm create $VMID \
    --name $VM_NAME \
    --cores $CORES \
    --memory $MEMORY \
    --net0 virtio,bridge=$BRIDGE \
    --scsihw virtio-scsi-pci \
    --scsi0 $STORAGE:0,format=qcow2,size=${DISK}G \
    --boot c --bootdisk scsi0 \
    --ide2 $ISO_TEMPLATE,media=cdrom

echo "▶ VM created. Start it and complete Ubuntu installation manually or via cloud-init."

# Generate random credentials for IaC stack
ADMIN_PASS=$(openssl rand -base64 16)
API_TOKEN=$(openssl rand -hex 16)

read -p "Enter VM IP address after installation: " VM_IP
SSH_USER="ubuntu"  # default user on Ubuntu live-server install

ssh $SSH_USER@$VM_IP bash -s <<EOF
set -e
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release git

# Install Docker from official repo
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
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
