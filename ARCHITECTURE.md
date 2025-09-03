# Architecture Documentation

This document describes the architecture of the Prometheus Development Environment, including system components, data flow, and design decisions.

## Table of Contents

- [Overview](#overview)
- [System Components](#system-components)
- [Architecture Diagrams](#architecture-diagrams)
- [Data Flow](#data-flow)
- [Deployment Options](#deployment-options)
- [Security Architecture](#security-architecture)
- [Networking](#networking)
- [Storage](#storage)
- [Scalability](#scalability)

## Overview

The Prometheus Development Environment is a containerized monitoring stack designed for:
- Easy local development and testing
- Multiple deployment configurations
- Secure authentication options
- Extensible architecture

### Design Principles

1. **Modularity**: Components can be swapped or extended
2. **Security First**: Authentication and credentials management built-in
3. **Developer Friendly**: Easy to start, stop, and configure
4. **Production Ready**: Follows best practices for production deployment

## System Components

### Core Components

```
┌───────────────────────────────────────────────────────────┐
│                    Prometheus Dev Environment             │
├───────────────────────────────────────────────────────────┤
│                                                           │
│  ┌─────────────┐     ┌──────────────┐    ┌──────────────┐ │
│  │   Nginx     │────▶│  Prometheus  │◀───│   Exporter   │ │
│  │   Proxy     │     │    Server    │    │ (Node/PCP)   │ │
│  └─────────────┘     └──────────────┘    └──────────────┘ │
│         │                    │                     │      │
│         ▼                    ▼                     ▼      │
│  ┌─────────────┐     ┌──────────────┐    ┌──────────────┐ │
│  │   Auth      │     │   Storage    │    │   Metrics    │ │
│  │  Config     │     │    (TSDB)    │    │   Source     │ │
│  └─────────────┘     └──────────────┘    └──────────────┘ │
│                                                           │
└───────────────────────────────────────────────────────────┘
```

### Component Details

#### 1. Prometheus Server
- **Image**: `docker.io/prom/prometheus:v2.47.0`
- **Purpose**: Time-series database and query engine
- **Ports**: 9090 (internal)
- **Configuration**: `/etc/prometheus/prometheus.yml`

#### 2. Nginx Reverse Proxy
- **Image**: `docker.io/nginx:alpine`
- **Purpose**: Authentication layer
- **Ports**: 
  - 9090: Basic Auth + Bearer + API Token
  - 9091: Bearer Token only
  - 9092: API Token only
- **Configuration**: `/etc/nginx/nginx.conf`

#### 3. Exporters

##### Node Exporter
- **Image**: `docker.io/prom/node-exporter:v1.7.0`
- **Purpose**: System and hardware metrics
- **Port**: 9100
- **Metrics**: CPU, memory, disk, network

##### PCP Exporter (Alternative)
- **Image**: `registry.fedoraproject.org/pcp:latest`
- **Purpose**: Performance Co-Pilot metrics
- **Port**: 44323
- **Metrics**: Advanced system performance data

#### 4. Management Scripts
- **Location**: `/scripts/`
- **Purpose**: Lifecycle management and operations
- **Components**:
  - `start.sh`: Initialize environment
  - `stop.sh`: Graceful shutdown
  - `status.sh`: Health checks
  - `test.sh`: Validation suite

## Architecture Diagrams

### Request Flow

```
Client Request
     │
     ▼
┌─────────────┐
│   Nginx     │ ← Authentication Check
│   (9090)    │
└─────────────┘
     │
     ├─ Authenticated ─▶ Pass to Prometheus
     │
     └─ Unauthorized ──▶ Return 401/403
```

### Data Collection Flow

```
System Metrics
     │
     ▼
┌─────────────┐     Pull Model    ┌──────────────┐
│  Exporter   │◀──────────────────│  Prometheus  │
│  (9100)     │    /metrics       │   (9090)     │
└─────────────┘                   └──────────────┘
                                         │
                                         ▼
                                  ┌──────────────┐
                                  │    TSDB      │
                                  │  Storage     │
                                  └──────────────┘
```

## Data Flow

### Metrics Collection

1. **Exporters** expose metrics on `/metrics` endpoint
2. **Prometheus** scrapes metrics at configured intervals
3. **Storage** persists data in time-series database
4. **Queries** retrieve data via PromQL

### Authentication Flow

1. **Client** sends request with credentials
2. **Nginx** validates against configured auth method:
   - Basic Auth: Check `.htpasswd`
   - Bearer Token: Validate token
   - API Token: Check custom header
3. **Proxy** forwards authenticated requests
4. **Response** returned to client

## Deployment Options

### 1. Standard Deployment
```yaml
# podman-compose.yml
- Prometheus + PCP Exporter
- No authentication
- Direct access
```

### 2. Node Exporter Deployment
```yaml
# podman-compose.node-exporter.yml
- Prometheus + Node Exporter
- System metrics focus
- Lightweight
```

### 3. Authenticated Deployment
```yaml
# podman-compose.auth.yml
- Prometheus + Exporter + Nginx
- Multi-auth support
- Production-ready
```

### 4. Custom Build
```yaml
# podman-compose.custom.yml
- Custom Prometheus image
- Development/debugging
- Extended features
```

## Security Architecture

### Credential Management

```
configs/credentials.env
├── Basic Auth Credentials
│   ├── PROM_ADMIN_USER/PASS
│   ├── PROM_USER_USER/PASS
│   └── PROM_VIEWER_USER/PASS
├── Token Authentication
│   ├── PROM_BEARER_TOKEN
│   └── PROM_API_TOKEN
└── Security Settings
    └── Rate Limits
```

### Security Layers

1. **Network Level**:
   - Container isolation
   - Internal network for backend
   - Exposed ports controlled

2. **Application Level**:
   - Authentication via Nginx
   - Rate limiting
   - No direct Prometheus access

3. **Data Level**:
   - Credentials never in code
   - Secure file permissions (600)
   - Environment separation

## Networking

### Network Architecture

```
External Network (Host)
     │
     ├─ Port 9090 ─▶ Nginx Proxy
     ├─ Port 9091 ─▶ Nginx (Bearer)
     ├─ Port 9092 ─▶ Nginx (API Token)
     └─ Port 9100 ─▶ Node Exporter (optional)
     
Internal Network (monitoring)
     │
     ├─ prometheus-dev:9090
     ├─ node-exporter:9100
     └─ prometheus-auth-proxy:80
```

### DNS Resolution

- Containers use service names for internal communication
- Bridge network provides isolation
- Custom subnet: `172.26.0.0/24`

## Storage

### Prometheus TSDB

- **Location**: `/prometheus` (container)
- **Volume**: `prometheus-data`
- **Retention**: 7 days (configurable)
- **Type**: Local persistent volume

### Configuration Storage

```
Host Filesystem          Container
──────────────           ─────────
./prometheus/      ───▶  /etc/prometheus/
./auth/            ───▶  /etc/nginx/
./configs/         ───▶  (environment vars)
```

## Scalability

### Vertical Scaling

Resource limits per container:
```yaml
prometheus:
  mem_limit: 1g
  cpus: 1.0

node-exporter:
  mem_limit: 128m
  cpus: 0.1

nginx:
  mem_limit: 128m
  cpus: 0.5
```

### Horizontal Scaling

For production environments:
1. Use Prometheus federation
2. Deploy multiple exporters
3. Implement service discovery
4. Add load balancing

### Performance Considerations

1. **Scrape Intervals**: Default 15s (adjustable)
2. **Retention Period**: 7 days (adjustable)
3. **Query Performance**: Indexed TSDB
4. **Network Overhead**: Minimal with local bridge

## Design Decisions

### Why Podman/Docker Compose?

- Simple local development
- Consistent environments
- Easy version management
- Portable configurations

### Why Nginx for Auth?

- Battle-tested solution
- Multiple auth methods
- Low overhead
- Easy configuration

### Why Separate Compose Files?

- Flexibility in deployment
- Clear separation of concerns
- Easy to maintain
- User choice

## Future Enhancements

1. **Service Discovery**: Consul/Kubernetes integration
2. **Alerting**: AlertManager integration
3. **Visualization**: Grafana dashboards
4. **Tracing**: OpenTelemetry support
5. **Clustering**: Multi-node Prometheus
