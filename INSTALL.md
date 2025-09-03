# Installation Guide

This guide provides detailed instructions for installing and setting up the Prometheus Development Environment.

## Table of Contents

- [System Requirements](#system-requirements)
- [Container Runtime Installation](#container-runtime-installation)
- [Project Setup](#project-setup)
- [Configuration](#configuration)
- [Verification](#verification)
- [Platform-Specific Notes](#platform-specific-notes)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Minimum Requirements

- **CPU**: 2 cores
- **RAM**: 2GB available
- **Disk**: 1GB free space
- **OS**: Linux, macOS, or Windows with WSL2

### Recommended Requirements

- **CPU**: 4+ cores
- **RAM**: 4GB+ available
- **Disk**: 10GB+ free space
- **Network**: Stable internet for pulling images

### Software Dependencies

Required:
- Container runtime: Podman 3.0+ or Docker 20.10+
- Compose tool: podman-compose 1.0+ or docker-compose 2.0+
- Shell: Bash 4.0+

Optional:
- Python 3.8+ (for authentication testing)
- jq (for JSON processing in scripts)
- curl or wget (for health checks)
- htpasswd (for generating auth files)

## Container Runtime Installation

### Podman (Recommended)

#### Fedora/RHEL/CentOS

```bash
# Install Podman and compose
sudo dnf install -y podman podman-compose

# (Optional) Install rootless dependencies
sudo dnf install -y slirp4netns fuse-overlayfs

# Enable podman socket for compose
systemctl --user enable --now podman.socket
```

#### Ubuntu/Debian

```bash
# Add Kubic repository
. /etc/os-release
echo "deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/ /" | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
curl -L "https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${VERSION_ID}/Release.key" | sudo apt-key add -

# Install Podman
sudo apt update
sudo apt install -y podman

# Install podman-compose
pip3 install podman-compose
```

#### macOS

```bash
# Using Homebrew
brew install podman
brew install podman-compose

# Initialize and start Podman machine
podman machine init
podman machine start
```

#### Windows

1. Install WSL2:
   ```powershell
   wsl --install
   ```

2. Install Podman Desktop from https://podman-desktop.io/

3. Or use WSL2 and follow Linux instructions

### Docker (Alternative)

#### Linux

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install docker-compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### macOS/Windows

Download and install Docker Desktop from https://www.docker.com/products/docker-desktop/

## Project Setup

### 1. Clone the Repository

```bash
# Using HTTPS
git clone https://github.com/Avilir/prom-dev.git

# Using SSH
git clone git@github.com:Avilir/prom-dev.git

# Enter directory
cd prom-dev
```

### 2. Set Permissions

```bash
# Make scripts executable
chmod +x scripts/*.sh
chmod +x scripts/lib/*.sh
chmod +x auth/generate-htpasswd.sh
```

### 3. Install Additional Tools

```bash
# Install jq for JSON processing
# Fedora/RHEL
sudo dnf install -y jq

# Ubuntu/Debian
sudo apt install -y jq

# macOS
brew install jq

# Install htpasswd for auth
# Fedora/RHEL
sudo dnf install -y httpd-tools

# Ubuntu/Debian
sudo apt install -y apache2-utils
```

### 4. Python Environment (Optional)

For authentication testing tools:

```bash
# Create virtual environment
python3 -m venv .venv

# Activate it
source .venv/bin/activate  # Linux/macOS
# or
.venv\Scripts\activate     # Windows

# Install requirements
pip install -r scripts/requirements.txt
```

## Configuration

### Basic Configuration

1. **Choose your deployment**:
   - Node Exporter (default): System metrics
   - PCP Exporter: Performance Co-Pilot
   - Custom: Your own Prometheus build

2. **Configure Prometheus**:
   ```bash
   # Edit Prometheus configuration
   vim prometheus/prometheus.yml
   
   # Or use the Node Exporter config
   vim prometheus/prometheus-node-exporter.yml
   ```

### Authentication Configuration

1. **Create credentials file**:
   ```bash
   cp configs/credentials.env.example configs/credentials.env
   ```

2. **Generate secure credentials**:
   ```bash
   # Generate passwords
   openssl rand -base64 32
   
   # Generate tokens
   openssl rand -hex 32
   
   # Generate UUID
   uuidgen
   ```

3. **Edit credentials**:
   ```bash
   # Edit the file
   vim configs/credentials.env
   
   # Replace ALL default values:
   # - PROM_ADMIN_PASS=CHANGE_ME_ADMIN_PASSWORD
   # - PROM_BEARER_TOKEN=CHANGE_ME_BEARER_TOKEN
   # - etc.
   ```

4. **Secure the file**:
   ```bash
   chmod 600 configs/credentials.env
   ```

### Network Configuration

1. **Firewall setup** (if needed):
   ```bash
   # Run the firewall configuration script
   ./scripts/firewall-setup.sh
   
   # Or manually:
   sudo firewall-cmd --add-port=9090/tcp --permanent
   sudo firewall-cmd --add-port=9100/tcp --permanent
   sudo firewall-cmd --reload
   ```

2. **Custom ports**:
   Edit the compose files to change port mappings:
   ```yaml
   ports:
     - "8080:9090"  # Change 8080 to your desired port
   ```

## Verification

### 1. Verify Installation

```bash
# Check container runtime
podman --version
# or
docker --version

# Check compose
podman-compose --version
# or
docker-compose --version

# Check other tools
jq --version
curl --version
```

### 2. Test Container Runtime

```bash
# Test Podman
podman run --rm hello-world

# Test Docker
docker run --rm hello-world
```

### 3. Pull Images

```bash
# Pre-pull images to verify connectivity
podman pull docker.io/prom/prometheus:v2.47.0
podman pull docker.io/prom/node-exporter:v1.7.0
podman pull docker.io/nginx:alpine
```

### 4. Start Environment

```bash
# Start without authentication
./scripts/start.sh

# Verify it's running
./scripts/status.sh

# Check logs
./scripts/logs.sh prometheus-dev
```

### 5. Access Web UI

Open http://localhost:9090 in your browser

## Platform-Specific Notes

### Linux

- SELinux may require additional configuration:
  ```bash
  # Allow containers to access volumes
  sudo setsebool -P container_manage_cgroup true
  ```

- For rootless Podman:
  ```bash
  # Enable lingering for user services
  loginctl enable-linger $USER
  ```

### macOS

- Podman uses a VM, ensure it's running:
  ```bash
  podman machine start
  ```

- Port forwarding is automatic but may need adjustment for non-standard ports

### Windows/WSL2

- Ensure WSL2 is using the correct distribution:
  ```powershell
  wsl --set-default Ubuntu
  ```

- File permissions may need adjustment:
  ```bash
  # In WSL2
  chmod 755 scripts/*.sh
  ```

## Troubleshooting

### Common Issues

1. **Permission denied on scripts**:
   ```bash
   chmod +x scripts/*.sh
   ```

2. **Cannot connect to Podman**:
   ```bash
   # Start podman socket
   systemctl --user start podman.socket
   ```

3. **Port already in use**:
   ```bash
   # Find what's using port 9090
   sudo lsof -i :9090
   # or
   sudo netstat -tlnp | grep 9090
   ```

4. **Image pull failures**:
   ```bash
   # Check connectivity
   podman pull docker.io/library/hello-world
   
   # Use different registry
   podman pull quay.io/prometheus/prometheus
   ```

5. **Compose file errors**:
   ```bash
   # Validate compose file
   podman-compose -f podman-compose.yml config
   ```

### Getting Help

1. Check script output with verbose mode
2. Review container logs: `./scripts/logs.sh <container>`
3. Check system logs: `journalctl -xe`
4. Open an issue with error details

## Next Steps

After successful installation:

1. Read the [README.md](README.md) for usage instructions
2. Set up authentication if needed
3. Configure monitoring targets
4. Import sample dashboards
5. Set up alerting rules

## Uninstallation

To remove the environment:

```bash
# Stop all containers
./scripts/stop.sh

# Remove containers and networks
podman-compose down -v

# Remove images (optional)
podman rmi docker.io/prom/prometheus:v2.47.0
podman rmi docker.io/prom/node-exporter:v1.7.0

# Remove project directory
cd ..
rm -rf prom-dev
```
