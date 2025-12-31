#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-automated-vm"
STORAGE="local-lvm"       
BRIDGE="vmbr0"
DISK_SIZE="20G"           
MEMORY="4096"
CORES="2"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_NAME="jammy-server-cloudimg-amd64.qcow2"
### --------------

# 1. PREPARE THE CLOUD IMAGE
echo "▶ Preparing Cloud Image..."
if [ ! -f "/var/lib/vz/template/iso/$IMAGE_NAME" ]; then
    wget -q --show-progress -O "/var/lib/vz/template/iso/$IMAGE_NAME" "$IMAGE_URL"
fi

# 2. PROVISION VM
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

qm create $VMID --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --net0 virtio,bridge="$BRIDGE" \
    --scsihw virtio-scsi-pci --agent enabled=1,fstrim_cloned_disks=1

# 3. IMPORT DISK & CLOUD-INIT
echo "▶ Importing disk (No manual installation required)..."
qm importdisk $VMID "/var/lib/vz/template/iso/$IMAGE_NAME" "$STORAGE"
qm set $VMID --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set $VMID --ide2 "$STORAGE:cloudinit"
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --ipconfig0 ip=dhcp

# Inject SSH key for passwordless access
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "▶ Injecting host SSH Key..."
    qm set $VMID --sshkey ~/.ssh/id_rsa.pub
fi

qm resize $VMID scsi0 "$DISK_SIZE"

# 4. START VM
echo "▶ Booting VM..."
qm start $VMID

# 5. AUTOMATED IP DETECTION
echo -n "▶ Waiting for VM to report IP address via Guest Agent ."
VM_IP=""
while [ -z "$VM_IP" ]; do
    VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | grep -oP '(?<="ip-address": ")[1-9][0-9]*(\.[0-9]+){3}' | grep -v '127.0.0.1' | head -n 1 || echo "")
    echo -n "."
    sleep 3
done
echo -e "\n✔ VM detected at: $VM_IP"

# 6. WAIT FOR CLOUD-INIT TO FINISH
echo -n "▶ Waiting for Ubuntu first-boot configuration to complete ."
until ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" [ -f /var/lib/cloud/instance/boot-finished ] 2>/dev/null; do
    echo -n "."
    sleep 5
done
echo -e "\n✔ Ubuntu is ready!"

# 7. AUTOMATED DEPLOYMENT
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

echo "▶ Deploying IaC Stack via SSH..."
ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" bash -s <<EOF
set -e
# Now safe to run apt without lock errors
sudo apt update && sudo apt install -y git curl

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker \$USER

# Clone and Deploy
sudo mkdir -p /opt/IaC && sudo chown \$USER:\$USER /opt/IaC
git clone https://github.com/jasonmcmullen/IaC.git /opt/IaC
cd /opt/IaC

echo "ADMIN_PASSWORD=${ADMIN_PASS}" > .env
echo "API_TOKEN=${API_TOKEN}" >> .env

sudo docker compose up -d
EOF

echo "------------------------------------------------------------"
echo "✔ SUCCESS! IaC stack is live."
echo "✔ URL: http://$VM_IP"
echo "✔ ADMIN_PASS: $ADMIN_PASS"
echo "------------------------------------------------------------"