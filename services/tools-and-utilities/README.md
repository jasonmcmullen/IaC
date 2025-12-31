# Tools and Utilities

Essential utility services for home server management and functionality.

## Services Included

### 1. File Browser
**Web-based file management interface**

- **Image**: filebrowser/filebrowser:latest
- **Port**: 8080
- **URL**: http://localhost:8080
- **Default Credentials**: admin/admin

A simple, powerful file manager with a web interface. Perfect for organizing media and accessing files across your network.

**Resources**:
- [GitHub](https://github.com/filebrowser/filebrowser)
- [Official Website](https://filebrowser.org/)

**Configuration**:
- Set `FILE_BROWSER_ROOT` in .env to your media directory
- Default login: admin/admin (change immediately)
- Supports user management and permissions

### 2. Vaultwarden
**Self-hosted Bitwarden password manager**

- **Image**: vaultwarden/server:latest
- **Port**: 8000
- **URL**: http://localhost:8000
- **Admin Panel**: http://localhost:8000/admin

Fully compatible with Bitwarden clients and extensions. Store all passwords, emails, and payment information securely.

**Resources**:
- [GitHub](https://github.com/dani-garcia/vaultwarden)
- [Documentation](https://github.com/dani-garcia/vaultwarden/wiki)

**Setup**:
1. Set `VAULTWARDEN_ADMIN_TOKEN` to a secure random string
2. Access admin panel at `/admin` with your token
3. Create your user account on the login page
4. Download Bitwarden extensions for browser
5. Enable 2FA for security

### 3. Hoarder
**Bookmark everything app with AI features**

- **Image**: ghcr.io/hoarder-app/hoarder:latest
- **Port**: 3000
- **URL**: http://localhost:3000
- **Database**: PostgreSQL (hoarder-db)
- **Search**: Meilisearch (hoarder-meilisearch)

A personal bookmarking and link collection tool with AI-powered features. Perfect for hoarding interesting content you find online.

**Features**:
- Automatic link title and description fetching
- Image and PDF storage
- Full-text search
- AI-powered content organization
- Note-taking capability

**Resources**:
- [GitHub](https://github.com/hoarder-app/hoarder)
- [Official Website](https://hoarder.app/)

**Setup**:
1. First run creates admin user - set credentials
2. Access web UI immediately to create account
3. Browser extension available for quick saves
4. AI features require configuration

### 4. Portainer
**Docker container management UI**

- **Image**: portainer/portainer-ce:latest
- **Port**: 9000
- **URL**: http://localhost:9000
- **Initial Setup**: Create admin user on first access

Powerful Docker management interface. Monitor containers, manage stacks, and deploy applications without command line.

**Resources**:
- [Documentation](https://docs.portainer.io/)
- [GitHub](https://github.com/portainer/portainer)

**Features**:
- Container lifecycle management
- Stack deployment via Docker Compose
- Image management
- Volume and network management
- System resource monitoring
- Multi-host management

### 5. OctoPrint
**3D printer management interface**

- **Image**: octoprint/octoprint:latest
- **Port**: 5000
- **URL**: http://localhost:5000

Control and monitor your 3D printer remotely. Upload gcode, manage prints, monitor progress, and view webcam feeds.

**Resources**:
- [GitHub](https://github.com/OctoPrint/OctoPrint)
- [Official Website](https://octoprint.org/)

**Setup**:
1. Uncomment device lines in docker-compose.yml for your printer's USB connection
2. Configure printer model in web UI
3. Upload gcode files for printing
4. Optional: Configure webcam for print monitoring

**Available Plugins**:
- Bed visualization
- Print time estimation
- Power control
- Timelapse recording

## Startup Instructions

### Start all Tools and Utilities
```bash
cd services/tools-and-utilities
docker-compose up -d
```

### Start specific service
```bash
docker-compose up -d file-browser vaultwarden
```

### View service logs
```bash
docker-compose logs -f vaultwarden
```

## Default Ports

| Service | Port | URL |
|---------|------|-----|
| File Browser | 8080 | http://localhost:8080 |
| Vaultwarden | 8000 | http://localhost:8000 |
| Vaultwarden Admin | 8000 | http://localhost:8000/admin |
| Hoarder | 3000 | http://localhost:3000 |
| Portainer | 9000 | http://localhost:9000 |
| OctoPrint | 5000 | http://localhost:5000 |

## Database Information

### Hoarder Database
- **Service**: hoarder-db (PostgreSQL)
- **User**: hoarder
- **Password**: hoarder
- **Database**: hoarder
- **Port**: 5432 (internal only)

### Hoarder Search
- **Service**: hoarder-meilisearch
- **Port**: 7700 (internal only)

## Environment Variables

Key variables to configure in `.env`:

```env
FILE_BROWSER_PORT=8080
FILE_BROWSER_ROOT=/mnt/media

VAULTWARDEN_PORT=8000
VAULTWARDEN_ADMIN_TOKEN=your-secure-token-here

HOARDER_PORT=3000

PORTAINER_PORT=9000
PORTAINER_EDGE_PORT=8001

OCTOPRINT_PORT=5000
```

## Security Considerations

### File Browser
- Change default credentials immediately
- Use reverse proxy with SSL for remote access
- Restrict file browser root to media directory

### Vaultwarden
- Use strong admin token (40+ characters)
- Enable 2FA on your user account
- Keep admin panel access restricted
- Regularly backup Vaultwarden data volume

### Hoarder
- Set strong database passwords
- Disable public registration if not needed
- Use reverse proxy with SSL

### Portainer
- Set strong admin password
- Restrict network access
- Keep Docker socket secure (local only)
- Regularly update Portainer image

### OctoPrint
- Set API key and disable API if not needed
- Restrict network access if exposed
- Keep printer firmware updated

## Backup Strategy

### Critical Volumes
1. **vaultwarden-data** - Contains encrypted vault
2. **hoarder-data** - User bookmarks and content
3. **hoarder-db-data** - Hoarder database
4. **portainer-data** - Portainer stacks and configuration

Backup script (see `/scripts/backup.sh`):
```bash
./scripts/backup.sh
```

## Networking

All services connect to the `homeserver` Docker network for inter-service communication.

To expose services:
1. Use NGINX Proxy Manager (see dns-and-connections)
2. Configure reverse proxy with SSL
3. Use DuckDNS or Cloudflare DDNS for dynamic DNS

## Troubleshooting

### Hoarder won't start
- Ensure PostgreSQL and Meilisearch start first
- Check logs: `docker-compose logs hoarder-db`
- Verify database password in compose file

### Vaultwarden shows connection errors
- Verify admin token is set in .env
- Check domain setting in environment variables
- Ensure firewall allows port 8000

### OctoPrint doesn't find printer
- Check USB device is passed to container
- Verify permissions on USB device
- Check OctoPrint logs for device errors

### Portainer can't connect to Docker
- Verify `/var/run/docker.sock` is mounted
- Check Docker daemon is running
- On Windows/Mac, Docker Desktop must be running

## Next Steps

1. **Secure your setup**: Set strong passwords for all services
2. **Configure backups**: Run backup script regularly
3. **Enable monitoring**: Add Prometheus/Grafana
4. **Set up reverse proxy**: Use NGINX Proxy Manager for remote access
5. **Configure 2FA**: Enable on Vaultwarden and Hoarder

## Additional Resources

- [TechHut Tools and Utilities Video](https://techhut.tv/must-have-home-server-services-2025/#tools-and-utilities)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Linuxserver.io](https://www.linuxserver.io/)

---

**Last Updated**: December 30, 2025
