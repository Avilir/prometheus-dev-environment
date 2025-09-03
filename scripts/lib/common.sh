#!/bin/bash
# Common functions and variables for prom-dev scripts
# Author: Avi Layani
# Purpose: Reduce code duplication across scripts

# Colors for output
export GREEN='\033[0;32m'
export RED='\033[0;31m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m' # No Color

# Get script locations
get_script_dir() {
    echo "$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
}

get_project_dir() {
    echo "$(cd "$(dirname "$(get_script_dir)")" && pwd)"
}

# Error handling
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit "${2:-1}"
}

# Success message
success_msg() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Warning message
warning_msg() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Info message
info_msg() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Check if container is running
check_container() {
    local container_name="$1"
    podman ps --format "{{.Names}}" 2>/dev/null | grep -q "^${container_name}$"
}

# Get container status
get_container_status() {
    local container_name="$1"
    podman ps -a --filter "name=^${container_name}$" --format "{{.Status}}" 2>/dev/null || echo "Not found"
}

# Determine which compose file to use based on running containers
get_active_compose_file() {
    local project_dir="${1:-$(get_project_dir)}"
    
    if check_container "prometheus-auth-proxy"; then
        echo "${project_dir}/podman-compose.auth.yml"
    elif check_container "node-exporter"; then
        echo "${project_dir}/podman-compose.node-exporter.yml"
    elif check_container "pcp-exporter"; then
        echo "${project_dir}/podman-compose.yml"
    else
        # Default to main compose file
        echo "${project_dir}/podman-compose.yml"
    fi
}

# Check if prometheus is accessible
check_prometheus_health() {
    local url="${1:-http://localhost:9090}"
    local auth_args="${2:-}"
    
    local cmd="curl -s -o /dev/null -w '%{http_code}' --max-time 5 ${auth_args} '${url}/-/healthy'"
    local http_code=$(eval "$cmd" 2>/dev/null || echo "000")
    
    [ "$http_code" = "200" ]
}

# Wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local url="$2"
    local timeout="${3:-60}"
    local auth_args="${4:-}"
    
    echo -n "Waiting for $service_name to be ready..."
    
    local elapsed=0
    while [ $elapsed -lt $timeout ]; do
        if check_prometheus_health "$url" "$auth_args"; then
            echo -e " ${GREEN}Ready!${NC}"
            return 0
        fi
        echo -n "."
        sleep 2
        elapsed=$((elapsed + 2))
    done
    
    echo -e " ${RED}Timeout!${NC}"
    return 1
}

# Export functions for use in sourcing scripts
export -f error_exit
export -f success_msg
export -f warning_msg
export -f info_msg
export -f check_container
export -f get_container_status
export -f get_active_compose_file
export -f check_prometheus_health
export -f wait_for_service
