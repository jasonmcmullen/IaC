# Installation Guide

Complete guide to set up the Home Server IaC infrastructure.

## System Requirements

- **OS**: Linux (Ubuntu 20.04+, Debian 10+), macOS, or Windows with WSL2
- **CPU**: 2+ cores (4+ recommended)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Storage**: 50GB+ free space (depends on media collection)
- **Docker**: 20.10+ with Compose plugin
- **Network**: Gigabit or faster recommended

## Step 1: Install Docker and Docker Compose

### Ubuntu/Debian
```bash
# Update package manager
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add your user to docker group (logout/login required)
sudo usermod -aG docker $USER
```

### macOS
```bash
# Using Homebrew
brew install docker docker-compose
# or download Docker Desktop from https://www.docker.com/products/docker-desktop
```

### Windows (WSL2)
1. Install WSL2 and a Linux distribution
2. Install Docker Desktop with WSL2 backend
3. Enable WSL2 integration in Docker Desktop settings

### Verify Installation
```bash
docker --version
docker compose version
```

## Step 2: Clone Repository

```bash
# Clone the IaC repository
git clone <repository-url> ~/homeserver-iac
cd ~/homeserver-iac

# Or create from scratch
mkdir -p ~/homeserver-iac
cd ~/homeserver-iac
```

## Step 3: Create Directory Structure

```bash
# Create required directories
mkdir -p volumes
mkdir -p configs
mkdir -p media
mkdir -p backups

# Create media subdirectories (optional)
mkdir -p media/downloads
mkdir -p media/movies
mkdir -p media/tv
mkdir -p media/music
mkdir -p media/photos
```

## Step 4: Configure Environment

```bash
# Copy example environment file
cp .env.example .env

# Edit with your settings
nano .env  # or vim .env or your preferred editor
```

### Essential Environment Variables to Set

```env
# Network
DOMAIN=your-domain.com
EXTERNAL_IP=192.168.1.100

# Timezone
TZ=America/New_York  # Change to your timezone

# Vaultwarden
VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -base64 32)

# Nextcloud
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=your-secure-password

# Grafana
GRAFANA_ADMIN_PASSWORD=your-secure-password

# File paths
FILE_BROWSER_ROOT=/mnt/media
VOLUMES_ROOT=/docker-volumes
MEDIA_PATH=/mnt/media
```

Generate secure tokens:
```bash
# Generate random token
openssl rand -base64 32

# Or use python
python3 -c "import secrets; print(secrets.token_urlsafe(32))"
```

## Step 5: Create Networks and Volumes

```bash
# Create custom network
docker network create homeserver

# Docker will auto-create named volumes, but you can pre-create them:
docker volume create file-browser-data
docker volume create vaultwarden-data
# ... etc
```

## Step 6: Start Services

### Option 1: Start All Services
```bash
# Start all services in background
docker compose up -d

# Or with specific compose files
docker compose -f services/tools-and-utilities/docker-compose.yml up -d
```

### Option 2: Start Specific Services
```bash
# Start only tools and utilities
cd services/tools-and-utilities
docker compose up -d

# Start only specific services
docker compose up -d file-browser vaultwarden
```

### Option 3: Staged Startup (Recommended)

Start services in order of dependency:

```bash
# 1. Start foundational services first
docker compose -f services/tools-and-utilities/docker-compose.yml up -d vaultwarden

# 2. Start dashboard services
docker compose -f services/dashboards/docker-compose.yml up -d

# 3. Add more services gradually
docker compose -f services/files-and-images/docker-compose.yml up -d
```

## Step 7: Verify Installation

```bash
# Check all containers are running
docker compose ps

# View service logs
docker compose logs -f

# Check specific service
docker compose logs -f vaultwarden

# Test connectivity
curl http://localhost:8080  # File Browser
curl http://localhost:8000  # Vaultwarden
curl http://localhost:3000  # Hoarder
```

## Step 8: Initial Configuration

### File Browser
1. Access http://localhost:8080
2. Default login: admin/admin
3. Change password immediately
4. Create additional users if needed

### Vaultwarden
1. Access http://localhost:8000
2. Create new account
3. Access admin panel at http://localhost:8000/admin with your token
4. Configure signup settings
5. Enable 2FA (recommended)

### Hoarder
1. Access http://localhost:3000
2. Create account on first access
3. Configure AI features if desired
4. Install browser extension

### Portainer (Docker Management)
1. Access http://localhost:9000
2. Create admin user on first access
3. Connect to local Docker socket
4. Explore containers and logs

## Step 9: Set Up Reverse Proxy (Optional but Recommended)

For secure remote access:

```bash
# Start NGINX Proxy Manager
docker compose -f services/dns-and-connections/docker-compose.yml up -d nginx-proxy-manager

# Access at http://localhost:81
# Default: admin@example.com / changeme
```

Configure:
1. Add proxy hosts for each service
2. Generate SSL certificates
3. Set up authentication if desired

## Step 10: Configure Backups

```bash
# Make backup script executable
chmod +x scripts/backup.sh

# Test backup
./scripts/backup.sh

# Schedule daily backups (Linux/macOS)
# Add to crontab:
# 0 2 * * * /path/to/homeserver-iac/scripts/backup.sh

# Schedule daily backups (Windows)
# Use Task Scheduler to run: scripts/backup.sh
```

## Step 11: Security Hardening

```bash
# Change all default passwords
# - File Browser admin
# - Vaultwarden accounts
# - Portainer admin
# - All database passwords

# Set up firewall rules
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
# Add ports for your exposed services

# Enable SSL/TLS for all services
# Use NGINX Proxy Manager or Let's Encrypt

# Keep containers updated
docker pull $(docker ps -q --format '{{.Image}}' | sort -u)
docker compose up -d
```

## Troubleshooting Installation

### Docker daemon not running
```bash
# Linux
sudo systemctl start docker

# macOS with Docker Desktop
# Open Docker Desktop application

# Windows with WSL2
# Ensure Docker Desktop is running with WSL2 integration
```

### Permission denied errors
```bash
# Add user to docker group (Linux)
sudo usermod -aG docker $USER
newgrp docker

# Restart docker daemon
sudo systemctl restart docker
```

### Port already in use
```bash
# Find process using port
lsof -i :8080

# Kill process or change port in .env
# Example: FILE_BROWSER_PORT=8081
```

### Containers exiting immediately
```bash
# Check logs for errors
docker compose logs <service-name>

# Common issues:
# - Missing environment variables
# - Port conflicts
# - Volume permission issues
# - Database connection failures
```

### Network connectivity issues
```bash
# Test network
docker network ls
docker network inspect homeserver

# Restart network
docker network rm homeserver
docker network create homeserver
docker compose down
docker compose up -d
```

## Next Steps

1. [Configure Services](CONFIGURATION.md)
2. [Set Up Networking](NETWORKING.md)
3. [Security Best Practices](SECURITY.md)
4. [Monitoring and Maintenance](MAINTENANCE.md)

## Useful Docker Commands

```bash
# View all containers
docker ps -a

# View container logs
docker logs <container-name>

# Enter container shell
docker exec -it <container-name> /bin/bash

# Restart services
docker compose restart <service-name>

# Update and restart
docker compose pull
docker compose up -d

# Remove stopped containers
docker container prune

# Remove unused volumes
docker volume prune

# View resource usage
docker stats
```

---

**Last Updated**: December 30, 2025
