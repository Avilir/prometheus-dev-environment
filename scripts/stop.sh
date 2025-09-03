#!/bin/bash
# Stop script for Prometheus development environment
# Author: Avi Layani
# Purpose: Stop the containerized Prometheus environment

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"

echo "🛑 Stopping Prometheus Development Environment..."
echo "================================================"

cd "$PROJECT_DIR"

# Parse command line arguments
COMPOSE_FILE=""
REMOVE_VOLUMES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --node-exporter)
            COMPOSE_FILE="podman-compose.node-exporter.yml"
            shift
            ;;
        --quay)
            COMPOSE_FILE="podman-compose.quay.yml"
            shift
            ;;
        --custom)
            COMPOSE_FILE="podman-compose.custom.yml"
            shift
            ;;
        --auth)
            COMPOSE_FILE="podman-compose.auth.yml"
            shift
            ;;
        -v|--volumes)
            REMOVE_VOLUMES=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --node-exporter    Stop Node Exporter setup"
            echo "  --quay            Stop Quay.io setup"
            echo "  --custom          Stop custom Dockerfile setup"
            echo "  --auth            Stop authentication setup"
            echo "  -v, --volumes     Remove volumes (delete all data)"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Try to detect which compose file is currently running
if [ -z "$COMPOSE_FILE" ]; then
    echo "🔍 Detecting running containers..."
    
    # Check which containers are running
    if podman ps --format "{{.Names}}" | grep -q "prometheus-auth-proxy"; then
        COMPOSE_FILE="podman-compose.auth.yml"
        echo "📋 Detected authentication setup (nginx proxy)"
    elif podman ps --format "{{.Names}}" | grep -q "node-exporter"; then
        COMPOSE_FILE="podman-compose.node-exporter.yml"
        echo "📋 Detected Node Exporter setup"
    elif podman ps --format "{{.Names}}" | grep -q "pcp-exporter"; then
        # Could be any of the PCP-based compose files
        # Default to the standard one
        COMPOSE_FILE="podman-compose.yml"
        echo "📋 Detected PCP setup (using default compose file)"
    else
        # Default to standard compose file
        COMPOSE_FILE="podman-compose.yml"
        echo "📋 Using default compose file"
    fi
fi

echo "📋 Using compose file: $COMPOSE_FILE"

# Check if compose file exists
if [ ! -f "$COMPOSE_FILE" ]; then
    echo "❌ Error: Compose file $COMPOSE_FILE not found!"
    exit 1
fi

# Stop the containers
echo "🔄 Stopping containers..."
podman-compose -f "$COMPOSE_FILE" down

# Remove volumes if requested
if [ "$REMOVE_VOLUMES" = true ]; then
    echo "🗑️  Removing volumes..."
    podman-compose -f "$COMPOSE_FILE" down -v
    echo "✅ Volumes removed"
fi

echo ""
echo "✅ Prometheus Development Environment stopped successfully!"

# Check if any containers are still running
# First check by label
RUNNING_BY_LABEL=$(podman ps --filter "label=project=prom-dev" --format "{{.Names}}" 2>/dev/null || true)
# Then check by name pattern (prometheus, exporter, proxy)
RUNNING_BY_NAME=$(podman ps --format "{{.Names}}" | grep -E "(prometheus|exporter|proxy)" 2>/dev/null || true)

# Combine and deduplicate
RUNNING_CONTAINERS=$(echo -e "$RUNNING_BY_LABEL\n$RUNNING_BY_NAME" | sort -u | grep -v '^$' || true)

if [ -n "$RUNNING_CONTAINERS" ]; then
    echo ""
    echo "⚠️  Warning: Some containers are still running:"
    echo "$RUNNING_CONTAINERS"
    echo ""
    echo "You may need to stop them manually with:"
    echo "  podman stop $RUNNING_CONTAINERS"
fi
