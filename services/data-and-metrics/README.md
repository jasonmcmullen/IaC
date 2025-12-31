# Data and Metrics

Monitoring, analytics, and metrics visualization services.

## Services Included

### Prometheus
Time-series database for collecting and storing metrics.

- **Image**: prom/prometheus:latest
- **Port**: 9090
- **Configuration**: YAML-based scrape configs
- **Retention**: Configurable (365 days recommended)
- **Purpose**: Metrics collection and storage

### Grafana
Beautiful dashboards and visualization platform.

- **Image**: grafana/grafana:latest
- **Port**: 3000
- **Dashboard**: Create custom visualizations
- **Data Sources**: Connect to Prometheus, InfluxDB, etc.
- **Alerts**: Alert notifications and rules

### InfluxDB 2.0
Purpose-built time-series database for metrics.

- **Image**: influxdb:latest
- **Port**: 8086
- **Purpose**: High-performance time-series storage
- **Use Cases**: Proxmox metrics, application metrics

### Node Exporter
System metrics collector for servers.

- **Image**: prom/node-exporter:latest
- **Port**: 9100
- **Metrics**: CPU, memory, disk, network, processes
- **Install**: On Raspberry Pi, Ubuntu, etc.

### TeslaMate
Collect and analyze Tesla vehicle data.

- **Image**: teslamate/teslamate:latest
- **Port**: 4000
- **Requirements**: Tesla account, vehicle
- **Features**: Trip tracking, efficiency analysis

## Configuration

### Prometheus Setup
1. Create config file: `prometheus.yml`
2. Define scrape targets:
   ```yaml
   scrape_configs:
     - job_name: 'prometheus'
       static_configs:
         - targets: ['localhost:9090']
     
     - job_name: 'node-exporter'
       static_configs:
         - targets: ['node-exporter:9100']
   ```
3. Prometheus reads targets and collects metrics
4. Access at http://localhost:9090

### Grafana Setup
1. Access http://localhost:3000
2. Default: admin / admin
3. **Change password immediately**
4. Add data sources:
   - Prometheus: http://prometheus:9090
   - InfluxDB: http://influxdb:8086
5. Import dashboards:
   - Dashboard → Import
   - Enter dashboard ID from Grafana.com
6. Create custom dashboards

### InfluxDB 2.0 Setup
1. Access http://localhost:8086
2. Initial setup wizard:
   - Create org, bucket, user
3. Create API token for applications
4. Add as data source in Grafana

### Node Exporter Installation
```bash
# Ubuntu/Debian
sudo apt-get install prometheus-node-exporter

# Or Docker
docker run -d \
  --name=node-exporter \
  --network=host \
  prom/node-exporter:latest

# Add to Prometheus scrape config
- job_name: 'raspberrypi'
  static_configs:
    - targets: ['192.168.1.50:9100']
```

### TeslaMate Setup
1. Access http://localhost:4000
2. Login with Tesla credentials
3. Authorize vehicle access
4. TeslaMate collects data automatically
5. View in Grafana dashboards

## Pre-built Dashboards

### Node Exporter Dashboard
Import ID: 1860
Shows:
- CPU usage
- Memory usage
- Disk I/O
- Network traffic
- Process information

### Proxmox Dashboard
Monitor Proxmox hypervisor:
- VM resource usage
- Network statistics
- Storage utilization
- Container performance

### TeslaMate Dashboard
Included in TeslaMate:
- Trip statistics
- Efficiency data
- Charging history
- Mileage tracking
- Cost analysis

## Metrics Collection

### Common Metrics
- **CPU**: Usage percentage, load average
- **Memory**: Used, available, cache
- **Disk**: Usage, I/O rates
- **Network**: Bytes sent/received, errors
- **Processes**: Running, sleeping, zombie
- **System**: Uptime, load

### Application Metrics
Export metrics from applications:
- Vaultwarden - can export metrics
- Home Assistant - history stats
- Container metrics - via cAdvisor

### Custom Metrics
Push custom data to Prometheus:
```bash
# Using pushgateway
curl -X POST --data-binary @metrics.txt \
  http://localhost:9091/metrics/job/custom
```

## Alerting

### Grafana Alerts
1. Edit panel
2. Add threshold
3. Configure notification channel
4. Set alert conditions

Example:
- CPU > 80% for 5 minutes → Send alert
- Disk > 90% → Send notification
- Service down → Create incident

### Alert Channels
- Email
- Slack
- Discord
- Telegram
- Webhooks
- PagerDuty

## Dashboard Examples

### Home Server Overview
```
┌─────────────────────────────────────┐
│ CPU Usage    │ Memory Usage         │
│ 45%          │ 6.2 GB / 16 GB       │
├─────────────────────────────────────┤
│ Disk Usage   │ Network Traffic      │
│ 420 GB / 2TB │ ↓ 5 Mbps ↑ 2 Mbps   │
├─────────────────────────────────────┤
│ Service Status                       │
│ ✓ Vaultwarden  ✓ Jellyfin          │
│ ✓ Nextcloud    ✓ Home Assistant     │
└─────────────────────────────────────┘
```

### Docker Container Monitoring
- Container CPU usage
- Memory consumption
- Network I/O
- Restart counts

## Performance Optimization

### Prometheus
- Adjust scrape interval (15s-60s)
- Limit retention based on disk
- Use federation for large setups
- Configure remote storage

### Grafana
- Limit dashboard refresh rates
- Use data downsampling
- Optimize queries
- Enable caching

### InfluxDB
- Use retention policies
- Archive old data
- Optimize database organization
- Monitor disk space

## Storage Management

### Prometheus Storage
```bash
# Check size
du -sh /prometheus

# Estimate retention
# Space needed = (samples/sec) × (duration) × 1.3
# Default: ~1-2 GB per year for typical home setup
```

### Data Retention Policy
```yaml
# Prometheus configuration
global:
  retention_time: 365d
  retention_size: 10GB
```

## Troubleshooting

### Metrics not appearing
```bash
# Check Prometheus targets
curl http://localhost:9090/api/v1/targets

# Verify Node Exporter running
curl http://node-exporter:9100/metrics

# Check Prometheus logs
docker logs prometheus
```

### Grafana dashboard blank
```bash
# Verify data source connected
Data Sources → Test

# Check query syntax
Panel → Edit → Query

# Review Prometheus query
http://localhost:9090/graph
```

### High disk usage
```bash
# Check retention settings
# Increase retention_time in Prometheus

# Or set size limit
retention_size: 5GB

# Archive old data
```

### InfluxDB slow queries
```bash
# Optimize bucket retention
# Settings → Buckets → Edit

# Check disk I/O
docker stats influxdb
```

## Advanced Monitoring

### Application Metrics Export
Enable in applications:
- Vaultwarden: Enable metrics endpoint
- Custom scripts: Export to Prometheus

### Infrastructure Monitoring
1. Node Exporter on each server
2. Prometheus collects from all
3. Grafana aggregates dashboards

### Cost Tracking
With TeslaMate or custom metrics:
- Energy consumption cost
- Data usage
- Vehicle fuel efficiency
- Hardware operational costs

## Backup Strategy

Critical volumes:
- prometheus-data: Metrics database
- grafana-data: Dashboards and config
- influxdb-data: InfluxDB data

Backup script:
```bash
./scripts/backup.sh
```

## API Access

### Prometheus API
Query metrics directly:
```bash
# Get CPU usage
curl 'http://localhost:9090/api/v1/query?query=node_cpu_seconds_total'

# Get range data
curl 'http://localhost:9090/api/v1/query_range?query=node_cpu_seconds_total&start=1577836800&end=1577923200&step=300'
```

### Grafana API
Manage dashboards programmatically:
```bash
# Get all dashboards
curl http://localhost:3000/api/search

# Get specific dashboard
curl http://localhost:3000/api/dashboards/uid/xxxxx
```

## Integration Ideas

### Monitor Home Server Components
- Track Vaultwarden usage
- Monitor Jellyfin streaming
- Watch Nextcloud storage
- Alert on service failures

### Energy Efficiency
- Track power consumption
- Set usage goals
- Identify inefficient services
- Optimize resource allocation

### Trend Analysis
- Identify growth patterns
- Forecast capacity needs
- Plan upgrades
- Detect anomalies

## Related Services

Works well with:
- Home Assistant (metrics export)
- Proxmox (VM monitoring)
- Docker (container metrics)
- Applications (custom metrics)

## Alternative Services

- **ELK Stack** - Elasticsearch, Logstash, Kibana
- **Loki** - Log aggregation
- **VictoriaMetrics** - Prometheus alternative
- **Datadog** - Commercial monitoring

---

**Last Updated**: December 30, 2025
