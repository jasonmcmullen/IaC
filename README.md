# 🛡️ Infrastructure as Code (IaC) Lab: Proxmox
> **Project Scope:** Fully automated, "Zero-Touch" provisioning for Proxmox VE 9.x. Includes interactive identity setup, automated ISO management, and security hardening.

---

## 🛠️ Lab Overview
This project centralizes the deployment of hardened Proxmox nodes. It eliminates manual input during installation by pre-hydrating templates with your specific UserID, SSH keys, and the latest official ISO.

### The Identity Handover
1.  **Workstation:** `build-media.sh` prompts for **UserID** and **SSH Key**.
2.  **ISO Management:** The script automatically fetches the latest Proxmox VE ISO.
3.  **Hydration:** Variables are injected into `answer.toml`.
4.  **USB (Ventoy):** Carries the custom UserID, Key, and ISO to the hardware.
5.  **New Node:** `setup-node.sh` creates the account and locks down the OS.

---

## 💻 Workstation Control Plane
The workstation handles the "heavy lifting" of preparing the deployment media.

### 1. Initialize Project Structure
```bash
mkdir -p ~/homelab/templates ~/homelab/dist ~/homelab/iso
```

### 2. Create the Answer Template (`templates/answer.toml.tmpl`)
```toml
[global]
keyboard = "en-us"
country = "ca"
timezone = "UTC"

[user]
# Password hash and SSH key injected from .env
password = "${PVE_ROOT_PASSWORD_HASH}" 
ssh_keys = ["${SSH_KEY_CONTENT}"]

[network]
source = "from-dhcp"

[disk]
selection = "first"
filesystem = "ext4"

[post-installation]
source = "from-url"
url = "https://raw.githubusercontent.com/YOUR_USER/YOUR_REPO/main/setup-node.sh"
# Arguments passed to the hardening script: [Key, Username]
script_arguments = ["${SSH_KEY_CONTENT}", "${ADMIN_USERNAME}"]
```

### 3. The Provisioning Wizard (`build-media.sh`)
This script automates the entire preparation phase.

```bash
#!/bin/bash
# --- 1. SETUP & SOURCE ---
mkdir -p ~/homelab/templates ~/homelab/dist ~/homelab/iso
[[ -f ~/homelab/.env ]] && source ~/homelab/.env

echo "--- Proxmox IaC Provisioning Suite ---"

# --- 2. IDENTITY WIZARD ---
read -p "Enter Admin UserID [${ADMIN_USERNAME:-adminuser}]: " INPUT_USER
ADMIN_USERNAME=${INPUT_USER:-${ADMIN_USERNAME:-adminuser}}

if [[ -z "$SSH_KEY_CONTENT" ]]; then
    read -p "Paste your SSH Public Key (id_ed25519.pub): " SSH_KEY_CONTENT
fi

# --- 3. DOWNLOAD LATEST PROXMOX ISO ---
ISO_URL="https://enterprise.proxmox.com/iso/proxmox-ve_latest.iso"
ISO_DEST="$HOME/homelab/iso/proxmox-ve_latest.iso"

if [[ ! -f "$ISO_DEST" ]]; then
    echo "Downloading latest Proxmox ISO..."
    curl -L "$ISO_URL" -o "$ISO_DEST"
else
    echo "Proxmox ISO already exists. Skipping download."
fi

# --- 4. PERSISTENCE & HYDRATION ---
cat <<EOF > ~/homelab/.env
SSH_KEY_CONTENT="$SSH_KEY_CONTENT"
ADMIN_USERNAME="$ADMIN_USERNAME"
PVE_ROOT_PASSWORD_HASH="$PVE_ROOT_PASSWORD_HASH"
EOF

export ADMIN_USERNAME SSH_KEY_CONTENT PVE_ROOT_PASSWORD_HASH
envsubst < ~/homelab/templates/answer.toml.tmpl > ~/homelab/dist/answer.toml

echo "------------------------------------------------"
echo "✅ Build Complete!"
echo "1. Generated Template: ~/homelab/dist/answer.toml"
echo "2. ISO Location: $ISO_DEST"
echo "------------------------------------------------"
```

---

## 🚀 Rapid Node Rollout (Ventoy)
1.  **Prepare USB:** Install [Ventoy](https://www.ventoy.net/) on a flash drive.
2.  **Move ISO:** Copy the downloaded ISO from `~/homelab/iso/` to the root of the USB.
3.  **Move Config:** Copy the generated `answer.toml` from `~/homelab/dist/` to the `/ventoy/` folder on the USB.
4.  **Configure Ventoy:** Ensure your `ventoy/ventoy.json` points to the ISO and the `answer.toml` template.

---

## 🛡️ Post-Install Hardening (`setup-node.sh`)
This script is hosted on GitHub and executes on the server after the OS is installed.

```bash
#!/bin/bash
# --- CONFIGURATION ---
PUB_KEY=$1 
NEW_USER=$2

# --- 1. PRE-FLIGHT ---
[[ $EUID -ne 0 ]] && exit 1
[[ -z "$NEW_USER" ]] && NEW_USER="adminuser"

# --- 2. USER PROVISIONING ---
apt update && apt install -y sudo
adduser --disabled-password --gecos "" "$NEW_USER"
usermod -aG sudo "$NEW_USER"

# --- 3. SSH IDENTITY ---
USER_HOME=$(eval echo "~$NEW_USER")
mkdir -p "$USER_HOME/.ssh"
echo "$PUB_KEY" > "$USER_HOME/.ssh/authorized_keys"
chown -R "$NEW_USER":"$NEW_USER" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh" && chmod 600 "$USER_HOME/.ssh/authorized_keys"

# --- 4. HARDENING ---
# Disable Root Login and Password Auth
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart ssh

echo "Bootstrap Complete. Access via: ssh $NEW_USER@<IP>"
```

---

## 🔍 Verification

| Test | Command | Expected Result |
| :--- | :--- | :--- |
| **Custom Identity** | `ssh <ADMIN_USERNAME>@<IP>` | Successful Key-based Login |
| **Root Lockout** | `ssh root@<IP>` | Connection Refused / Permission Denied |
| **Privilege Esc** | `sudo whoami` | `root` |

---
> **Note:** This workflow treats hardware as cattle. By automating the ISO lifecycle and the identity injection, your entire lab environment remains reproducible, consistent, and documented as code.