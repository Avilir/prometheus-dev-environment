#!/bin/bash
# Logs script for Prometheus development environment
# Author: Avi Layani
# Purpose: View logs from containers

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"

# Default values
CONTAINER=""
FOLLOW=false
TAIL_LINES=100
TIMESTAMPS=true

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [CONTAINER]"
    echo ""
    echo "View logs from Prometheus development environment containers"
    echo ""
    echo "Containers:"
    echo "  prometheus, prometheus-dev    View Prometheus server logs"
    echo "  node, node-exporter          View Node Exporter logs"
    echo "  pcp, pcp-exporter           View PCP exporter logs"
    echo "  all                         View logs from all containers"
    echo ""
    echo "Options:"
    echo "  -f, --follow                Follow log output (like tail -f)"
    echo "  -n, --tail LINES           Number of lines to show (default: 100)"
    echo "  --no-timestamps            Don't show timestamps"
    echo "  -h, --help                 Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 prometheus              # Show last 100 lines of Prometheus logs"
    echo "  $0 -f node                 # Follow Node Exporter logs"
    echo "  $0 -n 50 all              # Show last 50 lines from all containers"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--follow)
            FOLLOW=true
            shift
            ;;
        -n|--tail)
            TAIL_LINES="$2"
            shift 2
            ;;
        --no-timestamps)
            TIMESTAMPS=false
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            CONTAINER="$1"
            shift
            ;;
    esac
done

# Map friendly names to container names
case "$CONTAINER" in
    prometheus|prometheus-dev)
        CONTAINER="prometheus-dev"
        ;;
    node|node-exporter)
        CONTAINER="node-exporter"
        ;;
    pcp|pcp-exporter)
        CONTAINER="pcp-exporter"
        ;;
    all)
        CONTAINER="all"
        ;;
    "")
        # No container specified, show available containers
        echo -e "${BLUE}📋 Available containers:${NC}"
        echo ""
        
        containers=$(podman ps --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" | grep -E "(prometheus-dev|node-exporter|pcp-exporter)" || echo "")
        
        if [ -n "$containers" ]; then
            echo "$containers"
            echo ""
            echo "Specify a container name to view its logs, or use 'all' to see all logs"
            echo "Example: $0 prometheus"
        else
            echo -e "${RED}No running containers found${NC}"
            echo ""
            echo "Start the environment first with:"
            echo "  ./scripts/start.sh"
        fi
        exit 0
        ;;
esac

# Build podman logs command
LOGS_CMD="podman logs"

if [ "$FOLLOW" = true ]; then
    LOGS_CMD="$LOGS_CMD -f"
fi

if [ "$TAIL_LINES" != "all" ]; then
    LOGS_CMD="$LOGS_CMD --tail $TAIL_LINES"
fi

if [ "$TIMESTAMPS" = true ]; then
    LOGS_CMD="$LOGS_CMD -t"
fi

# Function to display logs for a container
show_logs() {
    local container_name="$1"
    
    # Check if container exists
    if ! podman ps -a --format "{{.Names}}" | grep -q "^$container_name$"; then
        echo -e "${YELLOW}Container '$container_name' not found${NC}"
        return 1
    fi
    
    # Check if container is running
    if ! podman ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        echo -e "${YELLOW}Container '$container_name' is not running${NC}"
        # Show last logs anyway
    fi
    
    echo -e "${BLUE}=== Logs for $container_name ===${NC}"
    echo ""
    
    # Execute logs command
    eval "$LOGS_CMD $container_name"
    
    return 0
}

# Show logs based on selection
if [ "$CONTAINER" = "all" ]; then
    # Show logs from all containers
    containers="prometheus-dev node-exporter pcp-exporter"
    found_any=false
    
    for cont in $containers; do
        if podman ps -a --format "{{.Names}}" | grep -q "^$cont$"; then
            if [ "$found_any" = true ]; then
                echo ""
                echo ""
            fi
            show_logs "$cont" || true
            found_any=true
        fi
    done
    
    if [ "$found_any" = false ]; then
        echo -e "${RED}No containers found${NC}"
        exit 1
    fi
else
    # Show logs for specific container
    if ! show_logs "$CONTAINER"; then
        echo ""
        echo "Available containers:"
        podman ps -a --format "table {{.Names}}\t{{.Status}}" | grep -E "(prometheus-dev|node-exporter|pcp-exporter)" || echo "  None found"
        exit 1
    fi
fi
