#!/usr/bin/env bash
set -euo pipefail

### --- CONFIG ---
HOSTNAME="iac"
STORAGE="local-lvm"
BRIDGE="vmbr0"
DISK=16
MEMORY=4096
CORES=2
### --------------

# Ensure running on Proxmox
command -v pct >/dev/null || { echo "ERROR: Must run on Proxmox host."; exit 1; }

# Select next free CTID
CTID=$(pvesh get /cluster/nextid)
echo "▶ Using CTID: $CTID"

# Pick latest Ubuntu LTS template
echo "▶ Selecting latest Ubuntu LTS template..."
pveam update
OS=$(pveam available | awk '/ubuntu/ && /standard/ && /amd64/ && /2[02468]\.04/ {print $2}' | sort -V | tail -n1)
if [[ -z "$OS" ]]; then echo "ERROR: No Ubuntu LTS template found."; exit 1; fi
echo "▶ Template: $OS"

# Download template if missing
if ! ls /var/lib/vz/template/cache/$OS &>/dev/null; then
    pveam download local "$OS"
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

# Generate random credentials
ADMIN_PASS=$(openssl rand -base64 16)
API_TOKEN=$(openssl rand -hex 16)

echo "▶ Generated credentials:"
echo "Admin password: $ADMIN_PASS"
echo "API token: $API_TOKEN"

# Deploy IaC inside container
pct exec $CTID -- bash -c "
set -e
apt update
apt install -y docker.io docker-compose-plugin git
systemctl enable docker
mkdir -p /opt
cd /opt
git clone https://github.com/jasonmcmullen/IaC.git
cd IaC

# Write .env automatically
cat > .env <<EOF
ADMIN_PASSWORD=${ADMIN_PASS}
API_TOKEN=${API_TOKEN}
EOF

# Use modern Docker Compose plugin
docker compose up -d
"

echo "✔ IaC deployment complete"
echo "✔ Container ID: $CTID"
echo "✔ Credentials saved inside container at /opt/IaC/.env"
