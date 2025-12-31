# Dashboards

Dashboard and overview services for centralizing access to all home server applications.

## Services Included

### Glance
**Minimalist homepage and dashboard**

- **Image**: ghcr.io/glanceapp/glance:latest
- **Port**: 8081
- **Configuration**: Simple YAML-based config file
- **GitHub**: [glanceapp/glance](https://github.com/glanceapp/glance)

Features:
- Custom homepage with service links
- RSS feed integration
- Website monitoring
- Weather integration
- Simple, clean interface

### Homarr
**Feature-rich dashboard with deep integrations**

- **Image**: ghcr.io/homarr-labs/homarr:latest
- **Port**: 7575
- **GUI Configuration**: Graphical settings interface
- **GitHub**: [homarr-labs/homarr](https://github.com/homarr-labs/homarr)

Features:
- Deep *arr stack integration
- Docker integration
- Proxmox support
- Widget system
- Visual configuration

## Configuration

### Glance Configuration
Glance uses a `glance.yml` configuration file:

```yaml
branding:
  title: Home Server

pages:
  - name: Home
    columns: 3
    rows: 3

    widgets:
      - type: bookmarks
        links:
          - title: Vaultwarden
            url: http://vaultwarden:80
          - title: File Browser
            url: http://file-browser:80

      - type: rss
        feeds:
          - url: https://example.com/feed.xml

      - type: weather
        location: "New York"

      - type: monitor
        sites:
          - name: Home Server
            url: http://localhost
          - name: Vaultwarden
            url: http://vaultwarden:80
```

### Homarr Configuration
Homarr provides a graphical interface for configuration:

1. Access http://localhost:7575
2. Click settings (gear icon)
3. Add apps/widgets
4. Configure integrations
5. Customize layout

## Startup

```bash
# Start all dashboard services
cd services/dashboards
docker compose up -d

# Start specific dashboard
docker compose up -d glance
```

## Recommended Setup

**Start with Glance** for:
- Simplicity
- Low resource usage
- Quick setup
- Clean interface

**Upgrade to Homarr** when you want:
- More features
- Visual configuration
- *arr integrations
- Custom widgets

## Integration with Other Services

### Link to Vaultwarden
```yaml
- title: Password Manager
  url: http://vaultwarden:80
```

### Link to Portainer
```yaml
- title: Docker Management
  url: http://portainer:9000
```

### Monitor Service Health
```yaml
- type: monitor
  sites:
    - name: Vaultwarden
      url: http://vaultwarden:80
```

## Performance Considerations

- **Glance**: Minimal resource usage
- **Homarr**: Moderate resource usage
- Both suitable for small home servers

## Backup

Configuration files:
- Glance: `glance.yml` in config volume
- Homarr: Settings stored in database

Backup the service volumes regularly.

## Troubleshooting

### Dashboard not loading
```bash
docker logs glance
docker logs homarr
```

### Configuration not applying
- Restart container after config changes
- Verify YAML syntax for Glance
- Clear browser cache for Homarr

### Links not working
- Ensure services are running
- Use container names for internal links
- Use port numbers (e.g., `:80` vs default)

---

**Last Updated**: December 30, 2025
