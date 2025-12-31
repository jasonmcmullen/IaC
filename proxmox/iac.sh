#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
VM_NAME="iac-vm"
STORAGE="local-lvm"       # VM Disk Storage
ISO_STORAGE="local"       # ISO Storage ID
BRIDGE="vmbr0"
DISK_SIZE="16"            # GB (No 'G' suffix)
MEMORY="4096"
CORES="2"
ISO_NAME="ubuntu-22.04.3-live-server-amd64.iso"
ISO_URL="https://releases.ubuntu.com/22.04/$ISO_NAME"
### --------------

# 1. FIX ISO STORAGE PATHING
# We must ensure the file is in /var/lib/vz/template/iso/
# regardless of what the script thought earlier.
EXPECTED_ISO_DIR="/var/lib/vz/template/iso"
mkdir -p "$EXPECTED_ISO_DIR"

# Ensure Proxmox allows ISOs on this storage
pvesm set "$ISO_STORAGE" --content iso 2>/dev/null || true

ISO_PATH="$EXPECTED_ISO_DIR/$ISO_NAME"

if [ ! -f "$ISO_PATH" ]; then
    echo "▶ ISO not found at $ISO_PATH. Downloading..."
    wget -O "$ISO_PATH" "$ISO_URL"
fi

# 2. GET NEXT VMID
VMID=$(pvesh get /cluster/nextid)
echo "▶ Using VMID: $VMID"

# 3. CREATE VM (Base)
# We don't attach the disk in 'create' to avoid the LVM parse error
qm create $VMID \
    --name "$VM_NAME" \
    --cores "$CORES" \
    --memory "$MEMORY" \
    --net0 virtio,bridge="$BRIDGE" \
    --scsihw virtio-scsi-pci \
    --onboot 1

# 4. ALLOCATE DISK (The "16G" fix)
# By passing only the number, we avoid the LVM parsing bug
echo "▶ Creating $DISK_SIZE GB disk on $STORAGE..."
qm set $VMID --scsi0 "$STORAGE:$DISK_SIZE"

# 5. ATTACH ISO (The "volume does not exist" fix)
# We use the explicit path-based attachment if the label fails
echo "▶ Attaching ISO..."
qm set $VMID --ide2 "$ISO_STORAGE:iso/$ISO_NAME,media=cdrom"

# 6. BOOT CONFIG
qm set $VMID --boot order="ide2;scsi0"

# Start the VM
qm start $VMID

echo "------------------------------------------------------------"
echo "✔ VM $VMID created and started."
echo "✔ Please complete the Ubuntu installation via the Proxmox Console."
echo "------------------------------------------------------------"

# Generate Credentials
ADMIN_PASS=$(openssl rand -base64 12)
API_TOKEN=$(openssl rand -hex 16)

read -p "Enter VM IP address after install: " VM_IP
SSH_USER="ubuntu"

echo "▶ Deploying IaC to $VM_IP..."
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

echo "✔ Deployment complete: http://$VM_IP"