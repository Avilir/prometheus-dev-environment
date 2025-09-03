#!/bin/bash
# Start script for Prometheus development environment
# Author: Avi Layani
# Purpose: Start the containerized Prometheus environment

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"

echo "🚀 Starting Prometheus Development Environment..."
echo "================================================"

# Check if podman is installed
if ! command -v podman &> /dev/null; then
    error_exit "podman is not installed. Please install podman first."
fi

# Check if podman-compose is installed
if ! command -v podman-compose &> /dev/null; then
    error_exit "podman-compose is not installed. Please install podman-compose first."
fi

cd "$PROJECT_DIR"

# Parse command line arguments
COMPOSE_FILE="podman-compose.yml"
USE_NODE_EXPORTER=false
USE_QUAY=false
USE_CUSTOM=false
USE_AUTH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --node-exporter)
            USE_NODE_EXPORTER=true
            COMPOSE_FILE="podman-compose.node-exporter.yml"
            shift
            ;;
        --quay)
            USE_QUAY=true
            COMPOSE_FILE="podman-compose.quay.yml"
            shift
            ;;
        --custom)
            USE_CUSTOM=true
            COMPOSE_FILE="podman-compose.custom.yml"
            shift
            ;;
        --auth)
            USE_AUTH=true
            COMPOSE_FILE="podman-compose.auth.yml"
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --node-exporter    Use Node Exporter instead of PCP"
            echo "  --quay            Use Quay.io registry for Prometheus"
            echo "  --custom          Use custom Prometheus Dockerfile"
            echo "  --auth            Enable authentication with Nginx proxy"
            echo "  -h, --help        Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0                        # Basic setup without auth"
            echo "  $0 --node-exporter        # With Node Exporter"
            echo "  $0 --auth                 # With authentication enabled"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo "📋 Using compose file: $COMPOSE_FILE"

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    error_exit "Compose file $COMPOSE_FILE not found!"
fi

# If using auth, set up htpasswd file first
if [ "$USE_AUTH" = true ]; then
    echo "🔐 Setting up authentication..."
    
    # Load credentials
    echo "🔑 Loading credentials..."
    REQUIRE_CREDENTIALS=true source "$SCRIPT_DIR/lib/load-credentials.sh" || {
        echo ""
        echo "📝 To set up secure credentials:"
        echo "   1. cp configs/credentials.env.example configs/credentials.env"
        echo "   2. Edit configs/credentials.env with secure values"
        echo "   3. chmod 600 configs/credentials.env"
        echo ""
        exit 1
    }
    
    # Check if htpasswd file exists
    if [ ! -f "$PROJECT_DIR/auth/.htpasswd" ]; then
        echo "📝 Generating htpasswd file from credentials..."
        if [ -f "$PROJECT_DIR/auth/generate-htpasswd.sh" ]; then
            chmod +x "$PROJECT_DIR/auth/generate-htpasswd.sh"
            "$PROJECT_DIR/auth/generate-htpasswd.sh"
        else
            error_exit "generate-htpasswd.sh not found!"
        fi
    else
        echo "✅ Using existing htpasswd file"
    fi
    echo ""
fi

# Start the containers
echo "🔄 Starting containers..."
podman-compose -f "$COMPOSE_FILE" up -d

# Wait a bit for containers to start
echo "⏳ Waiting for services to be ready..."
sleep 5

# Check container status
echo ""
echo "📊 Container Status:"
podman-compose -f "$COMPOSE_FILE" ps

# Test connectivity
echo ""
echo "🔍 Testing connectivity..."

# Test Prometheus
if [ "$USE_AUTH" = true ]; then
    # Test without auth (should fail)
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/api/v1/query?query=up)
    if [ "$HTTP_CODE" = "401" ]; then
        echo "✅ Authentication is working (unauthorized without credentials)"
    else
        echo "⚠️  Expected 401 without auth, got HTTP $HTTP_CODE"
    fi
    
    # Test with auth (using loaded credentials)
    if curl -s -o /dev/null -w "%{http_code}" -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" http://localhost:9090/-/healthy | grep -q "200"; then
        echo "✅ Prometheus is healthy with authentication at http://localhost:9090"
    else
        echo "❌ Prometheus health check failed with authentication"
    fi
else
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy | grep -q "200"; then
        echo "✅ Prometheus is healthy at http://localhost:9090"
    else
        echo "❌ Prometheus health check failed"
    fi
fi

# Test exporter based on which one we're using
if [ "$USE_NODE_EXPORTER" = true ]; then
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:9100/metrics | grep -q "200"; then
        echo "✅ Node Exporter is healthy at http://localhost:9100"
    else
        echo "❌ Node Exporter health check failed"
    fi
else
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:44323/metrics | grep -q "200"; then
        echo "✅ PCP Exporter is healthy at http://localhost:44323"
    else
        echo "⚠️  PCP Exporter health check failed (this might be expected with the Fedora image)"
    fi
fi

echo ""
echo "🎉 Prometheus Development Environment is ready!"
echo ""
echo "📌 Access points:"
if [ "$USE_AUTH" = true ]; then
    echo "   - Prometheus UI: http://localhost:9090 (authentication required)"
    echo "   - Bearer Token Only: http://localhost:9091"
    echo "   - API Token Only: http://localhost:9092"
    echo "   - Node Metrics: http://localhost:9090/node-metrics"
else
    echo "   - Prometheus UI: http://localhost:9090"
    if [ "$USE_NODE_EXPORTER" = true ]; then
        echo "   - Node Exporter: http://localhost:9100/metrics"
    else
        echo "   - PCP Metrics: http://localhost:44323/metrics"
    fi
fi

if [ "$USE_AUTH" = true ]; then
    echo ""
    echo "🔐 Authentication Configuration:"
    echo "   Credentials loaded from: configs/credentials.env"
    echo "   Basic Auth users: $(cat $PROJECT_DIR/auth/.htpasswd 2>/dev/null | wc -l || echo "0") configured"
    echo "   Bearer Token: Configured"
    echo "   API Token: Configured"
    echo ""
    echo "   📋 To view/change credentials:"
    echo "      cat configs/credentials.env"
fi

echo ""
echo "💡 Tips:"
echo "   - Run './scripts/status.sh' to check container status"
if [ "$USE_AUTH" = true ]; then
    echo "   - Run './scripts/test.sh' to test connectivity, authentication, and data collection"
else
    echo "   - Run './scripts/test.sh' to test connectivity and data collection"
fi
echo "   - Run './scripts/logs.sh' to view container logs"
echo "   - Run './scripts/stop.sh' to stop the environment"
echo ""
