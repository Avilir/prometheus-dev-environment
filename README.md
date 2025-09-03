# Prometheus Development Environment

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Prometheus](https://img.shields.io/badge/Prometheus-2.47.0-orange)](https://prometheus.io/)
[![Podman Compatible](https://img.shields.io/badge/Podman-Compatible-purple)](https://podman.io/)
[![Docker Compatible](https://img.shields.io/badge/Docker-Compatible-blue)](https://www.docker.com/)
[![Development Environment](https://img.shields.io/badge/Environment-Development%20Only-red)]()

A comprehensive Prometheus development environment designed for local development and testing, featuring multiple deployment options, authentication support, and monitoring capabilities.

## ⚠️ Important Disclaimers

1. **Development Environment Only**: This Prometheus deployment is designed specifically for development and testing purposes. It is NOT intended for production use. For production deployments, please refer to the official [Prometheus documentation](https://prometheus.io/docs/prometheus/latest/installation/) and implement appropriate security hardening, high availability, and monitoring practices.

2. **AI-Assisted Development**: This project was developed with the assistance of AI tools, specifically [Cursor](https://cursor.sh/) and Claude AI. While every effort has been made to ensure code quality and security, please review and test thoroughly before using in your environment.

## 🚀 Features

- **Multiple Deployment Options**: Node Exporter, PCP Exporter, or custom configurations
- **Authentication Support**: Basic Auth, Bearer Tokens, and API Tokens via Nginx reverse proxy
- **Security Focused**: Centralized credential management for safe development practices
- **Easy Management**: Comprehensive scripts for starting, stopping, and monitoring
- **Flexible Configuration**: Support for custom Prometheus builds and configurations
- **Cross-Platform**: Works with both Podman and Docker
- **Monitoring Tools**: Pre-configured exporters and sample queries

## 📋 Table of Contents

- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [Architecture](#architecture)
- [Security](#security)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## 🔧 Requirements

- **Container Runtime**: Podman 3.0+ or Docker 20.10+
- **Compose Tool**: podman-compose or docker-compose
- **Operating System**: Linux, macOS, or Windows with WSL2
- **Memory**: Minimum 2GB RAM available
- **Disk Space**: At least 1GB free space

Optional:
- Python 3.8+ (for advanced authentication testing)
- htpasswd (for generating authentication files)

## 🏃 Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/Avilir/prom-dev.git
   cd prom-dev
   ```

2. **Start Prometheus** (no authentication):
   ```bash
   ./scripts/start.sh
   ```

3. **Access Prometheus**:
   - Open http://localhost:9090 in your browser
   - Metrics available at http://localhost:9100/metrics (Node Exporter)

4. **Check status**:
   ```bash
   ./scripts/status.sh
   ```

5. **Stop environment**:
   ```bash
   ./scripts/stop.sh
   ```

## 📦 Installation

For detailed installation instructions, see [INSTALL.md](INSTALL.md).

### Basic Installation

1. **Install container runtime**:
   ```bash
   # Fedora/RHEL/CentOS
   sudo dnf install podman podman-compose

   # Ubuntu/Debian
   sudo apt install podman podman-compose

   # macOS
   brew install podman podman-compose
   ```

2. **Verify installation**:
   ```bash
   podman --version
   podman-compose --version
   ```

3. **Configure firewall** (if needed):
   ```bash
   ./scripts/firewall-setup.sh
   ```

## ⚙️ Configuration

### Authentication Setup

1. **Create credentials file**:
   ```bash
   cp configs/credentials.env.example configs/credentials.env
   ```

2. **Generate secure passwords**:
   ```bash
   # Generate a secure password
   openssl rand -base64 32
   ```

3. **Edit credentials**:
   ```bash
   vim configs/credentials.env
   # Replace all CHANGE_ME values
   ```

4. **Secure the file**:
   ```bash
   chmod 600 configs/credentials.env
   ```

5. **Start with authentication**:
   ```bash
   ./scripts/start.sh --auth
   ```

### Deployment Options

- **Node Exporter** (default): System metrics collection
- **PCP Exporter**: Performance Co-Pilot integration
- **Custom Build**: Use your own Prometheus image
- **Authentication**: Nginx reverse proxy with multiple auth methods

## 📖 Usage

### Starting the Environment

```bash
# Default (Node Exporter, no auth)
./scripts/start.sh

# With authentication
./scripts/start.sh --auth

# Specific configuration
./scripts/start.sh --config node-exporter
```

### Monitoring Commands

```bash
# Check status
./scripts/status.sh

# View logs
./scripts/logs.sh prometheus-dev
./scripts/logs.sh node-exporter

# Run comprehensive tests (connectivity, auth, data collection)
./scripts/test.sh

# Advanced Python-based testing (optional)
./scripts/test-advanced.py
```

### Accessing Services

| Service | URL | Authentication |
|---------|-----|----------------|
| Prometheus UI | http://localhost:9090 | Optional |
| Prometheus Metrics | http://localhost:9090/metrics | Optional |
| Node Exporter | http://localhost:9100/metrics | No |
| Health Check | http://localhost:9090/-/healthy | No |

When authentication is enabled:
- Port 9090: Basic Auth + Bearer Token + API Token
- Port 9091: Bearer Token only
- Port 9092: API Token only

### Sample Queries

The `queries/` directory contains example PromQL queries:
- `basic.promql`: Essential queries for getting started
- `advanced.promql`: Complex aggregations and calculations
- `performance-testing.promql`: Load testing queries

## 🏗️ Architecture

For detailed architecture information, see [ARCHITECTURE.md](ARCHITECTURE.md).

### Components

1. **Prometheus Server**: Core time-series database
2. **Exporters**: Node Exporter or PCP for metrics collection
3. **Nginx Proxy**: Optional authentication layer
4. **Scripts**: Management and automation tools

### Directory Structure

```
prom-dev/
├── auth/                 # Authentication configuration
├── configs/             # Configuration files
├── docs/                # Documentation and examples
├── prometheus/          # Prometheus configurations
├── queries/             # Sample PromQL queries
├── scripts/             # Management scripts
│   └── lib/            # Shared script libraries
└── compose files        # Various deployment options
```

## 🔒 Security

For security policies and reporting, see [SECURITY.md](SECURITY.md).

### Best Practices

1. **Never commit credentials** to version control
2. **Use strong passwords** (32+ characters)
3. **Rotate credentials** regularly
4. **Limit network exposure** using firewall rules
5. **Enable authentication** for production use

### Credential Management

All credentials are centralized in `configs/credentials.env`:
- Basic authentication users and passwords
- Bearer tokens for API access
- API tokens for custom authentication

## 🐛 Troubleshooting

### Common Issues

1. **Port already in use**:
   ```bash
   # Find process using port 9090
   sudo lsof -i :9090
   # Or change the port in compose files
   ```

2. **Authentication failures**:
   ```bash
   # Check credentials are loaded
   source scripts/test-credentials.sh
   # Verify htpasswd file exists
   ls -la auth/.htpasswd
   ```

3. **Container startup issues**:
   ```bash
   # Check logs
   ./scripts/logs.sh prometheus-dev
   # Verify compose file
   podman-compose -f podman-compose.yml config
   ```

### Getting Help

1. Check the logs: `./scripts/logs.sh <container-name>`
2. Run status check: `./scripts/status.sh`
3. Enable verbose mode in scripts
4. Open an issue on GitHub

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Contribution Guide

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run tests
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

- [Prometheus](https://prometheus.io/) - The monitoring system
- [Node Exporter](https://github.com/prometheus/node_exporter) - Hardware and OS metrics
- [Nginx](https://nginx.org/) - Authentication proxy
- [Podman](https://podman.io/) - Container runtime

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/Avilir/prom-dev/issues)
- **Discussions**: [GitHub Discussions](https://github.com/Avilir/prom-dev/discussions)
- **Security**: See [SECURITY.md](SECURITY.md) for reporting vulnerabilities

---

Made with ❤️ by Avi Layani.  
Developed with assistance from [Cursor](https://cursor.sh/) and Claude AI