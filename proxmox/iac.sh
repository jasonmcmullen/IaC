#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
HOSTNAME="iac"
OS="ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
STORAGE="local-lvm"
BRIDGE="vmbr0"
DISK=16
MEMORY=4096
CORES=2
### --------------

# Ensure running on Proxmox
command -v pct >/dev/null || {
  echo "ERROR: This script must be run on a Proxmox host."
  exit 1
}

# Get next free CTID
CTID=$(pvesh get /cluster/nextid)

echo "▶ Creating IaC LXC (CTID: $CTID)"

# Ensure OS template exists
if ! ls /var/lib/vz/template/cache/$OS &>/dev/null; then
  echo "▶ Downloading OS template..."
  pveam update
  pveam download local $OS
fi

# Create container
pct create $CTID local:vztmpl/$OS \
  --hostname $HOSTNAME \
  --cores $CORES \
  --memory $MEMORY \
  --rootfs $STORAGE:$DISK \
  --net0 name=eth0,bridge=$BRIDGE,ip=dhcp \
  --unprivileged 1 \
  --features nesting=1,keyctl=1 \
  --onboot 1

pct start $CTID

echo "▶ Installing Docker and deploying IaC stack"

pct exec $CTID -- bash -c "
set -e
apt update
apt install -y docker.io docker-compose git
systemctl enable docker
mkdir -p /opt
cd /opt
git clone https://github.com/jasonmcmullen/IaC.git
cd IaC
[ -f .env ] || cp .env.example .env
docker-compose up -d
"

echo "✔ IaC deployment complete"
echo "✔ Container ID: $CTID"
