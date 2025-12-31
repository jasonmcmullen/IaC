# Quick Start Guide

Get your home server up and running in 15 minutes.

## Prerequisites (5 min)

1. **Install Docker**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install docker.io docker-compose
   
   # macOS
   brew install docker docker-compose
   
   # Windows: Download Docker Desktop
   ```

2. **Verify Installation**
   ```bash
   docker --version
   docker compose version
   ```

3. **Clone Repository**
   ```bash
   git clone <repo-url>
   cd IaC
   ```

## Basic Configuration (5 min)

1. **Copy Environment File**
   ```bash
   cp .env.example .env
   ```

2. **Generate Secure Token**
   ```bash
   openssl rand -base64 32
   ```

3. **Edit .env** with your settings:
   ```env
   VAULTWARDEN_ADMIN_TOKEN=<paste-token-here>
   TZ=America/New_York
   DOMAIN=homeserver.local
   ```

## Start Services (5 min)

### Option A: Core Services Only
```bash
# Start File Browser, Vaultwarden, Portainer
cd services/tools-and-utilities
docker compose up -d
```

### Option B: Everything
```bash
# Start all services
docker compose -f docker-compose.yml up -d
docker compose -f services/tools-and-utilities/docker-compose.yml up -d
docker compose -f services/dashboards/docker-compose.yml up -d
docker compose -f services/dns-and-connections/docker-compose.yml up -d
docker compose -f services/data-and-metrics/docker-compose.yml up -d
```

## Access Your Services

### Default URLs

| Service | URL | User | Pass |
|---------|-----|------|------|
| File Browser | http://localhost:8080 | admin | admin |
| Vaultwarden | http://localhost:8000 | Create account | - |
| Portainer | http://localhost:9000 | Create user | - |
| Hoarder | http://localhost:3000 | Create account | - |
| Glance Dashboard | http://localhost:8081 | - | - |
| Pi-hole | http://localhost | - | (from .env) |
| Grafana | http://localhost:3000 | admin | (from .env) |

## First Steps

1. **Change Default Passwords**
   - File Browser: admin/admin
   - Create Vaultwarden account
   - Set Portainer admin password

2. **Verify Services Running**
   ```bash
   docker compose ps
   ```

3. **View Logs**
   ```bash
   docker compose logs -f vaultwarden
   ```

4. **Create Backups**
   ```bash
   ./scripts/backup.sh
   ```

## Troubleshooting

### Services won't start
```bash
# Check logs
docker compose logs <service>

# Verify .env exists
cat .env

# Check ports aren't in use
lsof -i :8080
```

### Can't access services
```bash
# Verify containers running
docker ps | grep vaultwarden

# Test connectivity
curl http://localhost:8000

# Check firewall
sudo ufw status
```

### Database errors
```bash
# Check database logs
docker logs vaultwarden-db

# Reset database (dangerous!)
docker compose down -v
docker compose up -d
```

## Next Steps

1. **Read Full Documentation**
   - [Installation Guide](docs/INSTALLATION.md)
   - [Configuration Guide](docs/CONFIGURATION.md)
   - [Networking Guide](docs/NETWORKING.md)

2. **Deploy More Services**
   - Media Server (Jellyfin/Plex)
   - Download Clients (qBittorrent)
   - Media Management (Radarr/Sonarr)
   - Smart Home (Home Assistant)

3. **Set Up Remote Access**
   - NGINX Proxy Manager
   - SSL Certificates
   - Dynamic DNS

4. **Monitoring**
   - Prometheus + Grafana
   - Health checks
   - Activity logs

## Common Commands

```bash
# Start services
docker compose up -d

# Stop services
docker compose down

# View logs
docker compose logs -f

# Restart service
docker compose restart vaultwarden

# Update all images
docker compose pull
docker compose up -d

# Remove unused resources
docker system prune
```

## Security Reminders

⚠️ **Important**:
1. Change ALL default passwords immediately
2. Enable 2FA on Vaultwarden
3. Use HTTPS for remote access
4. Keep backups of critical volumes
5. Update containers regularly
6. Use strong passwords everywhere

## Performance Tips

- Start with basic services (File Browser, Vaultwarden)
- Add services gradually
- Monitor resource usage: `docker stats`
- Use SSD for database volumes
- Keep Docker updated

## Getting Help

- Check logs: `docker compose logs -f <service>`
- Read documentation in `docs/`
- Visit service GitHub pages
- Check TechHut blog: https://techhut.tv/

---

**Ready?** Run: `docker compose up -d` and access http://localhost:8080

**Need help?** See [INSTALLATION.md](docs/INSTALLATION.md) or service-specific READMEs in `services/` folder.

**Last Updated**: December 30, 2025
