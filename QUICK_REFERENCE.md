# Quick Reference Guide

## 🚀 Common Commands

### Environment Management
```bash
# Start (no auth)
./scripts/start.sh

# Start with authentication
./scripts/start.sh --auth

# Check status
./scripts/status.sh

# View logs
./scripts/logs.sh prometheus-dev
./scripts/logs.sh node-exporter

# Stop everything
./scripts/stop.sh
```

### Testing
```bash
# Comprehensive testing (connectivity, auth, data)
./scripts/test.sh

# Show loaded credentials
./scripts/show-credentials.sh

# Verbose testing
./scripts/test.sh -v

# Advanced Python testing
./scripts/test-advanced.py
```

### Credentials Setup
```bash
# First time setup
cp configs/credentials.env.example configs/credentials.env
vim configs/credentials.env
chmod 600 configs/credentials.env

# Generate secure passwords
openssl rand -base64 32
```

## 🌐 Access URLs

| Service | URL | Auth Required |
|---------|-----|---------------|
| Prometheus UI | http://localhost:9090 | When enabled |
| Prometheus API | http://localhost:9090/api/v1/ | When enabled |
| Node Exporter | http://localhost:9100/metrics | No |
| Health Check | http://localhost:9090/-/healthy | No |

## 🔧 Deployment Options

```bash
# Node Exporter (default)
podman-compose up -d

# With authentication
./scripts/start.sh --auth

# Custom Prometheus build
podman-compose -f podman-compose.custom.yml up -d

# Specific registry
podman-compose -f podman-compose.quay.yml up -d
```

## 📊 Useful PromQL Queries

```promql
# Check all targets
up

# CPU usage
rate(node_cpu_seconds_total[5m])

# Memory usage
node_memory_MemAvailable_bytes

# Disk usage
node_filesystem_avail_bytes

# Network traffic
rate(node_network_receive_bytes_total[5m])
```

## 🔐 Authentication Methods

### Basic Auth
```bash
curl -u admin:password http://localhost:9090/api/v1/query?query=up
```

### Bearer Token
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:9091/api/v1/query?query=up
```

### API Token
```bash
curl -H "X-API-Token: YOUR_TOKEN" http://localhost:9092/api/v1/query?query=up
```

## 🛠️ Troubleshooting

```bash
# Check if containers are running
podman ps

# Check container logs
podman logs prometheus-dev

# Test connectivity
curl -s http://localhost:9090/-/healthy

# Verify credentials loaded
echo $PROM_ADMIN_USER

# Reset everything
./scripts/stop.sh
podman system prune -a
./scripts/start.sh
```

## 📁 Important Files

- `configs/credentials.env` - Authentication credentials
- `prometheus/prometheus.yml` - Prometheus configuration
- `auth/nginx.conf` - Authentication proxy config
- `queries/*.promql` - Example queries

## 🔄 Container Management

```bash
# List containers
podman ps -a

# Restart a container
podman restart prometheus-dev

# Execute command in container
podman exec -it prometheus-dev sh

# Remove all containers
podman-compose down

# Remove everything including volumes
podman-compose down -v
```

## 📈 Performance Tuning

```yaml
# In compose files, adjust:
mem_limit: 2g      # Increase memory
cpus: 2.0          # Increase CPU

# In prometheus.yml:
scrape_interval: 30s    # Reduce load
retention: 30d          # Increase retention
```

## 🌟 Tips

1. Always use `--auth` for non-local deployments
2. Rotate credentials every 90 days
3. Monitor `/metrics` endpoint for self-monitoring
4. Use `./scripts/status.sh` to verify health
5. Check logs if containers fail to start

---
For full documentation, see README.md
