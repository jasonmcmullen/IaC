# Files and Images

Cloud storage and photo backup services.

## Services Included

### Nextcloud
Complete on-premise cloud replacement for Google Drive, OneDrive, etc.

- **Image**: nextcloud:latest
- **Port**: 8888
- **Database**: MySQL/MariaDB
- **Features**: Files, Calendar, Contacts, Tasks, and more

### Immich
Google Photos replacement with mobile app.

- **Image**: ghcr.io/immich-app/immich-server:latest
- **Port**: 2283
- **Mobile App**: Available on iOS and Android
- **Features**: Photo backup, facial recognition, location mapping

### Docmost
Personal wiki, knowledge base, and notes replacement for Notion.

- **Image**: ghcr.io/docmost/docmost:latest
- **Port**: 3001
- **Features**: Collaborative documents, wiki pages, notes

## Configuration

### Nextcloud Setup
1. Access http://localhost:8888
2. Create admin account (admin username/password)
3. Configure trusted domains:
   - Settings → Basic Settings
   - Add your domain
4. Enable 2FA (recommended)
5. Install mobile app for sync

### Immich Setup
1. Access http://localhost:2283
2. Create admin account
3. Download mobile app
4. Enable backup in app
5. Wait for initial sync

### Docmost Setup
1. Access http://localhost:3001
2. Create account
3. Create first workspace
4. Start adding pages

## Storage Organization

### Nextcloud
- **Personal**: Individual user files
- **Shared**: Team folders
- **External Storage**: Mount other storage backends

### Immich
- **Albums**: Organize by date/event
- **Memories**: Auto-generated albums
- **Archive**: Older photos
- **Favorites**: Starred photos

### Docmost
- **Workspaces**: Separate project areas
- **Pages**: Individual documents
- **Subpages**: Nested organization
- **Favorites**: Quick access

## Features

### Nextcloud
- File sync and sharing
- Calendar (CalDAV)
- Contacts (CardDAV)
- Tasks and notes
- Collaborative editing
- Version control
- Full-text search
- Activity monitoring

### Immich
- Automatic photo backup
- Facial recognition
- Location mapping
- Timeline view
- Face clustering
- Album organization
- Sharing with family
- Collaborative albums

### Docmost
- Rich text editing
- Markdown support
- Collaborative editing
- Comments and mentions
- Database/table support
- Integrations

## Performance Optimization

### Nextcloud
- Enable preview caching
- Use PHP-FPM for better performance
- Configure background jobs
- Enable full-text search with Elasticsearch

### Immich
- Use SSD for database
- Configure transcoding limits
- Archive old photos
- Use face recognition sparingly

## Backup Strategy

Critical volumes:
- `nextcloud-data`: All files and configurations
- `nextcloud-db`: Nextcloud database
- `immich-data`: Photos and metadata
- `immich-db`: Immich database

Backup script:
```bash
./scripts/backup.sh
```

## Networking

### Local Access
```
http://homeserver.local:8888/  # Nextcloud
http://homeserver.local:2283/  # Immich
http://homeserver.local:3001/  # Docmost
```

### Remote Access
Use NGINX Proxy Manager:
```
https://nextcloud.example.com
https://immich.example.com
https://docmost.example.com
```

## Mobile Apps

### Nextcloud
- iOS: App Store
- Android: Play Store or F-Droid
- WebDAV support in other apps

### Immich
- iOS: TestFlight
- Android: Google Play or F-Droid
- Requires app for backup feature

### Docmost
- Web-based only
- Works on mobile browsers

## Advanced Features

### Nextcloud Addons
- Deck (Kanban boards)
- Maps (location tracking)
- Mail (email client)
- Cookbook (recipe storage)
- And many more

### Immich Features
- Timeline grouped by month/year
- Search by text, date, location
- Shared links with expiration
- Partner sharing
- Library management

## Security

### Nextcloud
1. Enable 2FA for admin
2. Use strong passwords
3. Regular updates
4. HTTPS for remote access
5. Disable unnecessary apps

### Immich
1. Secure mobile app with PIN
2. Access controls per user
3. Backup to encrypted storage
4. Regular backups

### Docmost
1. User authentication
2. Access controls per workspace
3. Audit logs
4. Workspace deletion policy

## Troubleshooting

### Nextcloud slow
```bash
# Check database size
docker exec nextcloud-db du -sh /var/lib/mysql

# Enable opcache
# Settings → Admin → Performance
```

### Immich not finding photos
```bash
# Check permissions
docker exec immich-server ls -la /photos

# Force re-scan
# Settings → Library
```

### Docmost sync issues
```bash
# Clear browser cache
# Restart container
docker restart docmost
```

## Data Migration

### From Google Photos to Immich
1. Use Google Takeout to export
2. Upload to Immich via UI
3. Wait for processing

### From Google Drive to Nextcloud
1. Download from Google Drive
2. Upload to Nextcloud via Web UI
3. Or use WebDAV client

## Recommended Deployment Order

1. **Nextcloud** - Start with cloud storage
2. **Immich** - Add photo management
3. **Docmost** - Add document/wiki functionality

## Related Services

- **Home Assistant** - Trigger actions on photo events
- **Grafana** - Monitor storage usage
- **NGINX Proxy Manager** - Secure remote access

---

**Last Updated**: December 30, 2025
