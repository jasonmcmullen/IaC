# Home Server Infrastructure as Code

Complete Infrastructure as Code (IaC) setup for self-hosted home server services, following the [TechHut Must-Have Homelab Services 2025](https://techhut.tv/must-have-home-server-services-2025/) guide.

## Overview

This repository provides containerized Docker deployments for essential home server applications organized by category:

- **Tools and Utilities** - File management, password management, bookmarks, containerization, system management
- **Dashboards** - Web interfaces for service discovery and monitoring
- **Media Server** - Jellyfin, Plex, and monitoring
- **Media Management** - Radarr, Sonarr, Lidarr, Bazarr, Prowlarr, Overseerr
- **Download Clients** - qBittorrent, NZBGet
- **Files and Images** - Nextcloud, Immich, Docmost
- **Smart Home and Automation** - Home Assistant, Frigate, Zigbee2MQTT
- **DNS and Remote Connections** - Pi-hole, NGINX Proxy Manager, Twingate, Cloudflare DDNS
- **Data and Metrics** - Grafana, Prometheus, InfluxDB, TeslaMate

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- 4GB+ RAM recommended
- Linux/macOS or Windows with WSL2

### Installation

1. Clone this repository:
`bash
git clone <your-repo-url>
cd IaC
`

2. Copy the environment template:
`bash
cp .env.example .env
`

3. Edit .env with your configuration

4. Start services:
```bash
docker-compose up -d
```

#### Proxmox one-liner ⚡

If you're running Proxmox, you can create an LXC and deploy the IaC stack with a single command (please inspect the script before running):

```bash
bash -c "$(wget -qLO - https://raw.githubusercontent.com/jasonmcmullen/IaC/main/proxmox/iac.sh)"
```

## Project Structure

- **services/** - Organized Docker Compose files for each service category
- **docs/** - Detailed documentation for setup and configuration
- **configs/** - Configuration files for various services
- **scripts/** - Deployment and backup helper scripts

## Tools and Utilities

Key services in this category:
- **File Browser** - Web-based file management
- **Vaultwarden** - Self-hosted Bitwarden password manager
- **Hoarder** - Bookmark everything app
- **Portainer** - Docker container management UI
- **Cockpit** - Server management web interface
- **OctoPrint** - 3D printer management

## Quick Links

- [Installation Guide](docs/INSTALLATION.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Networking Setup](docs/NETWORKING.md)
- [Service Documentation](services/)

## License

This repository is provided as-is. Individual services have their own licenses.

## Resources

- [TechHut Blog - Must-Have Homelab Services 2025](https://techhut.tv/must-have-home-server-services-2025/)
- [Linuxserver.io](https://www.linuxserver.io/)
- [Docker Documentation](https://docs.docker.com/)

---

**Last Updated**: December 30, 2025
