#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-automated-vm"
STORAGE="local-lvm"       
BRIDGE="vmbr0"
DISK_SIZE="20G"           
MEMORY="4096"
CORES="2"
# Use the Cloud Image (.img) instead of an ISO
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_NAME="jammy-server-cloudimg-amd64.qcow2"
### --------------

# 1. DOWNLOAD CLOUD IMAGE (Pre-installed OS)
EXPECTED_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_DIR"
if [ ! -f "$EXPECTED_DIR/$IMAGE_NAME" ]; then
    echo "▶ Downloading Cloud Image (Only happens once)..."
    wget -q --show-progress -O "$EXPECTED_DIR/$IMAGE_NAME" "$IMAGE_URL"
fi

# 2. PROVISION VM
VMID=$(pvesh get /cluster/nextid)
echo "▶ Provisioning VM $VMID..."
qm create $VMID --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --net0 virtio,bridge="$BRIDGE" \
    --scsihw virtio-scsi-pci --agent enabled=1

# 3. ATTACH DISK & AUTO-CONFIG
echo "▶ Importing disk (Skipping manual installation)..."
qm importdisk $VMID "$EXPECTED_DIR/$IMAGE_NAME" "$STORAGE"
qm set $VMID --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set $VMID --ide2 "$STORAGE:cloudinit"
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --ipconfig0 ip=dhcp

# Inject YOUR host's SSH key so you don't need a password to run the script
if [ -f ~/.ssh/id_rsa.pub ]; then
    echo "▶ Injecting SSH key for hands-off access..."
    qm set $VMID --sshkey ~/.ssh/id_rsa.pub
fi

qm resize $VMID scsi0 "$DISK_SIZE"
qm start $VMID

# 4. AUTOMATED WAIT LOGIC (No console clicking needed)
echo -n "▶ Waiting for Guest Agent to report IP address "
VM_IP=""
while [ -z "$VM_IP" ]; do
    VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | grep -oP '(?<="ip-address": ")[1-9][0-9]*(\.[0-9]+){3}' | grep -v '127.0.0.1' | head -n 1 || echo "")
    echo -n "."
    sleep 3
done
echo -e "\n✔ VM is live at: $VM_IP"

echo -n "▶ Waiting for Ubuntu to finish background setup (Cloud-Init) "
until ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" [ -f /var/lib/cloud/instance/boot-finished ] 2>/dev/null; do
    echo -n "."
    sleep 5
done
echo -e "\n✔ OS is ready. Deploying IaC stack..."

# 5. DEPLOYMENT
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" bash -s <<EOF
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

echo "------------------------------------------------------------"
echo "✔ COMPLETE! No manual installation was required."
echo "✔ URL: http://$VM_IP"
echo "✔ Password: $ADMIN_PASS"
echo "------------------------------------------------------------"