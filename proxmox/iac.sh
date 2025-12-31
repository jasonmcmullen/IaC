#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-fully-auto"
STORAGE="local-lvm"       
BRIDGE="vmbr0"
DISK_SIZE="20G"           
MEMORY="4096"
CORES="2"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_NAME="jammy-server-cloudimg-amd64.qcow2"
### --------------

# 1. INSTALL HOST TOOLS (Required to modify images)
echo "▶ Ensuring host has libguestfs-tools..."
apt update -q && apt install -y libguestfs-tools >/dev/null 2>&1

# 2. DOWNLOAD & PRE-INSTALL GUEST AGENT
EXPECTED_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_DIR"

if [ ! -f "$EXPECTED_DIR/$IMAGE_NAME" ]; then
    echo "▶ Downloading Cloud Image..."
    wget -q --show-progress -O "$EXPECTED_DIR/$IMAGE_NAME" "$IMAGE_URL"
    
    echo "▶ Injecting QEMU Guest Agent into image (One-time setup)..."
    # This modifies the image file directly so it boots with the agent already there
    virt-customize -a "$EXPECTED_DIR/$IMAGE_NAME" --install qemu-guest-agent
fi

# 3. PROVISION VM
VMID=$(pvesh get /cluster/nextid)
echo "▶ Provisioning VM $VMID..."
qm create $VMID --name "$VM_NAME" --memory "$MEMORY" --cores "$CORES" --net0 virtio,bridge="$BRIDGE" \
    --scsihw virtio-scsi-pci --agent enabled=1

qm importdisk $VMID "$EXPECTED_DIR/$IMAGE_NAME" "$STORAGE"
qm set $VMID --scsi0 "$STORAGE:vm-$VMID-disk-0"
qm set $VMID --ide2 "$STORAGE:cloudinit"
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --ipconfig0 ip=dhcp

if [ -f ~/.ssh/id_rsa.pub ]; then
    qm set $VMID --sshkey ~/.ssh/id_rsa.pub
fi

qm resize $VMID scsi0 "$DISK_SIZE"
qm start $VMID

# 4. AUTOMATED IP DETECTION (Now it will work!)
echo -n "▶ Waiting for Guest Agent to report IP "
VM_IP=""
while [ -z "$VM_IP" ]; do
    # The agent usually takes ~30 seconds to start during first boot
    VM_IP=$(qm guest cmd $VMID network-get-interfaces 2>/dev/null | grep -oP '(?<="ip-address": ")[1-9][0-9]*(\.[0-9]+){3}' | grep -v '127.0.0.1' | head -n 1 || echo "")
    echo -n "."
    sleep 5
done
echo -e "\n✔ VM detected at: $VM_IP"

# 5. WAIT FOR CLOUD-INIT
echo -n "▶ Waiting for Ubuntu configuration to finish "
until ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" [ -f /var/lib/cloud/instance/boot-finished ] 2>/dev/null; do
    echo -n "."
    sleep 5
done

# 6. DEPLOYMENT
ADMIN_PASS=$(openssl rand -base64 12)
echo "▶ Deploying IaC Stack..."
ssh -o StrictHostKeyChecking=no "ubuntu@$VM_IP" bash -s <<EOF
sudo apt update && sudo apt install -y git curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker \$USER
sudo mkdir -p /opt/IaC && sudo chown \$USER:\$USER /opt/IaC
git clone https://github.com/jasonmcmullen/IaC.git /opt/IaC
cd /opt/IaC
echo "ADMIN_PASSWORD=${ADMIN_PASS}" > .env
sudo docker compose up -d
EOF

echo "------------------------------------------------------------"
echo "✔ SUCCESS! URL: http://$VM_IP"
echo "------------------------------------------------------------"