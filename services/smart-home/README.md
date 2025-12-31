# Smart Home and Automation

Home automation, security monitoring, and device integration services.

## Services Included

### Home Assistant
Complete home automation platform with integrations for 1000+ devices.

- **Image**: homeassistant/home-assistant:latest
- **Port**: 8123
- **Database**: SQLite/PostgreSQL
- **Language**: YAML configuration + UI
- **Mobile App**: iOS and Android

### Frigate
Open-source NVR (Network Video Recorder) with AI object detection.

- **Image**: ghcr.io/blakeblackshear/frigate:latest
- **Port**: 5000
- **Features**: AI object detection (with Coral TPU), recording, playback
- **Camera Support**: RTSP, HTTP, WebRTC

### Zigbee2MQTT
Bridge for Zigbee devices using MQTT protocol.

- **Image**: koenkk/zigbee2mqtt:latest
- **Port**: 8080
- **Protocol**: Zigbee to MQTT
- **Devices**: Lights, switches, sensors, etc.

## Configuration

### Home Assistant Setup
1. Access http://localhost:8123
2. Create account (first user is admin)
3. Onboarding wizard:
   - Location settings
   - Unit system
4. Add integrations:
   - MQTT (for Zigbee2MQTT)
   - Frigate (for cameras)
   - Google Home / Alexa (optional)
5. Create automations and scripts

### Frigate Setup
1. Access http://localhost:5000
2. Configure cameras:
   - RTSP URL
   - Resolution
   - FPS
3. Configure detection:
   - Object detection enabled
   - CPU or Coral TPU
4. Set recording preferences

### Zigbee2MQTT Setup
1. Configure USB adapter:
   - /dev/ttyUSB0 for Linux
   - COM3 for Windows
   - Adapter model (CC2531, ConBee, etc.)
2. Access UI at port 8080
3. Pair devices:
   - Put adapter in pairing mode
   - Reset Zigbee device
   - Wait for pairing confirmation
4. Name devices appropriately

## Home Assistant Features

### Automation Examples
```yaml
automation:
  - alias: "Turn on lights at sunset"
    trigger:
      platform: sun
      event: sunset
    action:
      service: light.turn_on
      data:
        entity_id: light.living_room
        brightness: 200

  - alias: "Send notification on motion"
    trigger:
      platform: state
      entity_id: binary_sensor.front_door_motion
      to: "on"
    action:
      service: notify.mobile_app_phone
      data:
        message: "Motion detected at front door"
```

### Scripts
Create complex sequences:
```yaml
script:
  bedtime:
    sequence:
      - service: light.turn_off
        data:
          entity_id: all
      - service: lock.lock
        data:
          entity_id: lock.front_door
      - service: climate.set_temperature
        data:
          entity_id: climate.thermostat
          temperature: 65
```

### Automations with Triggers
- Time-based (at specific time)
- Event-based (device state change)
- Sensor-based (temperature, motion)
- Location-based (arrive/leave)
- Integration-based (voice assistants)

## Frigate Features

### Object Detection
With Coral TPU:
- Person detection
- Car/vehicle detection
- Pet detection
- Custom object detection

### Recording
- Continuous recording
- Event-based recording
- Motion-triggered clips
- Retention policies

### Playback and Search
- Review recorded video
- Search by object type
- Timeline view
- Export clips

## Zigbee Device Integration

### Supported Devices
- **Lights**: Philips Hue, IKEA Tradfri
- **Switches**: Various on/off switches
- **Sensors**: Temperature, humidity, motion
- **Locks**: Door locks
- **Plugs**: Smart outlets

### Pairing Process
1. Enable pairing mode on Zigbee2MQTT
2. Reset device (hold button 10+ seconds)
3. Watch for connection in UI
4. Rename in Zigbee2MQTT
5. Automatically appears in Home Assistant

## MQTT Integration

### Zigbee2MQTT → Home Assistant
MQTT connection:
1. Home Assistant settings → Integrations
2. Add MQTT
3. Broker: mqtt (container name)
4. Zigbee topics automatically discovered

### Custom MQTT Automations
```yaml
automation:
  - alias: "React to Zigbee motion sensor"
    trigger:
      platform: mqtt
      topic: zigbee2mqtt/living_room_motion
      payload: "true"
    action:
      service: light.turn_on
      entity_id: light.living_room
```

## Notifications

### Mobile App
1. Download Home Assistant app
2. Sign in with account
3. Receive notifications
4. Control devices from phone

### Email/Discord/Telegram
Configure notifiers:
```yaml
notify:
  - platform: smtp
    server: smtp.gmail.com
    from: your@email.com
  - platform: discord
    token: YOUR_DISCORD_TOKEN
```

## Scenes and Automations

### Scene Example - "Movie Mode"
```yaml
scene:
  - name: movie_mode
    entities:
      light.living_room:
        state: off
      light.kitchen:
        state: off
      climate.thermostat:
        temperature: 72
```

Trigger with:
- Voice command
- Automation
- Manual button

## Performance and Storage

### Database Management
- SQLite default (good for small setups)
- PostgreSQL recommended (larger setups)
- Regular backups essential

### Storage Optimization
- Archive old recordings
- Limit retention policies
- Clean event database
- Monitor disk usage

## Security Considerations

1. **Authentication**: Use strong passwords
2. **HTTPS**: Enable reverse proxy with SSL
3. **2FA**: Enable if available
4. **Tokens**: Use API tokens, not passwords
5. **Firewall**: Restrict network access
6. **Updates**: Keep Home Assistant updated

## Backup and Restore

### Backup
```bash
# Home Assistant backup
docker exec homeassistant \
  tar czf /config/backup-$(date +%Y%m%d).tar.gz /config

# Or use built-in backup in UI
```

### Restore
1. Stop Home Assistant
2. Restore config directory
3. Restart services

## Troubleshooting

### Cameras not connecting
```bash
# Check Frigate logs
docker logs frigate

# Verify RTSP URL format
# rtsp://user:pass@ip:554/path

# Test connection
ffprobe rtsp://camera-url
```

### Zigbee devices not pairing
```bash
# Check USB adapter detected
ls -la /dev/ttyUSB*

# View Zigbee logs
docker logs zigbee2mqtt

# Adapter may need reset
# Hold pairing button 5+ seconds
```

### Automations not triggering
```bash
# Check automation syntax in YAML
# Automation editor → Validate YAML

# View automation logs
Settings → System → Logs

# Restart Home Assistant
docker restart homeassistant
```

### High RAM usage
- Disable unnecessary integrations
- Archive old events
- Reduce history retention
- Optimize automations

## Advanced Features

### Template Sensors
Create custom entities:
```yaml
sensor:
  - platform: template
    sensors:
      average_temperature:
        value_template: >
          {{ ((float(states('sensor.room1_temp')) +
               float(states('sensor.room2_temp'))) / 2) | round(1) }}
```

### RESTful Integration
Connect external services:
```yaml
automation:
  - trigger:
      platform: webhook
      webhook_id: my_webhook
    action:
      service: light.turn_on
```

### History Stats
Track automation effectiveness:
```yaml
sensor:
  - platform: history_stats
    name: Bedroom lights on today
    entity_id: light.bedroom
    state: "on"
    type: time
    period:
      days: 1
```

## Integration Ideas

### Energy Monitoring
- Track power usage
- Set reduction goals
- Automate based on consumption

### Weather Integration
- Adjust lights based on daylight
- Automation triggers on rain/snow
- Warnings for severe weather

### Security System
- Integrate cameras with motion sensors
- Automations for entry/exit
- Notifications on alarm
- Lock/unlock automations

## Deployment Order

1. **Home Assistant** - Foundation
2. **Zigbee2MQTT** - Device bridge
3. **Frigate** - Security cameras
4. **Additional integrations** - As needed

## Storage and Backup

Critical volumes:
- homeassistant-config: All configuration
- frigate-recordings: Camera footage

Backup strategy:
```bash
./scripts/backup.sh
```

---

**Last Updated**: December 30, 2025
