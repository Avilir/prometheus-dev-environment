#!/bin/bash
# Status script for Prometheus development environment
# Author: Avi Layani
# Purpose: Check the status of all components

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Source common library
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"

# Load credentials (don't require them - status should work without auth too)
REQUIRE_CREDENTIALS=false source "$SCRIPT_DIR/lib/load-credentials.sh" 2>/dev/null || true

echo "📊 Prometheus Development Environment Status"
echo "==========================================="
echo ""

# Function to check service status
check_service() {
    local service_name="$1"
    local url="$2"
    local container_name="$3"
    
    echo -e "${BLUE}$service_name:${NC}"
    
    # Check container status
    if podman ps --format "{{.Names}}" | grep -q "^$container_name$"; then
        # Get container details
        container_info=$(podman ps --filter "name=$container_name" --format "Status: {{.Status}}, Up: {{.RunningFor}}, ID: {{.ID}}")
        echo -e "  Container: ${GREEN}✅ Running${NC}"
        echo "  $container_info"
        
        # Get container health if available
        health=$(podman inspect "$container_name" --format '{{.State.Health.Status}}' 2>/dev/null || echo "none")
        if [ "$health" != "none" ] && [ -n "$health" ]; then
            if [ "$health" = "healthy" ]; then
                echo -e "  Health: ${GREEN}✅ $health${NC}"
            else
                echo -e "  Health: ${YELLOW}⚠️  $health${NC}"
            fi
        fi
    else
        echo -e "  Container: ${RED}❌ Not running${NC}"
    fi
    
    # Check HTTP endpoint if provided
    if [ -n "$url" ]; then
        # Check if auth is required (nginx proxy is running)
        if podman ps --format "{{.Names}}" 2>/dev/null | grep -q "prometheus-auth-proxy" && [[ "$url" == *"localhost:9090"* ]]; then
            # Use basic auth for port 9090 when auth proxy is running
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" "$url" 2>/dev/null || echo "000")
        else
            http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
        fi
        
        if [ "$http_code" = "200" ]; then
            echo -e "  Endpoint: ${GREEN}✅ Accessible${NC} ($url)"
        elif [ "$http_code" = "302" ] || [ "$http_code" = "401" ]; then
            echo -e "  Endpoint: ${YELLOW}⚠️  Auth required${NC} ($url) [HTTP $http_code]"
        else
            echo -e "  Endpoint: ${RED}❌ Not accessible${NC} ($url) [HTTP $http_code]"
        fi
    fi
    
    echo ""
}

# Check if auth is required (set this early)
AUTH_REQUIRED=false
if podman ps --format "{{.Names}}" | grep -q "prometheus-auth-proxy"; then
    AUTH_REQUIRED=true
fi

# Check if auth proxy is running
if [ "$AUTH_REQUIRED" = true ]; then
    check_service "Nginx Auth Proxy" "http://localhost:9090" "prometheus-auth-proxy"
    echo -e "${BLUE}Authentication Status:${NC}"
    echo "  Port 9090: Basic Auth + Bearer + API Token"
    echo "  Port 9091: Bearer Token Only"  
    echo "  Port 9092: API Token Only"
    echo ""
fi

# Check Prometheus
check_service "Prometheus Server" "http://localhost:9090/-/healthy" "prometheus-dev"

# Check which exporter is running
if podman ps --format "{{.Names}}" | grep -q "node-exporter"; then
    if [ "$AUTH_REQUIRED" = true ]; then
        # When auth is enabled, node exporter is accessed through proxy
        check_service "Node Exporter" "http://localhost:9090/node-metrics" "node-exporter"
    else
        check_service "Node Exporter" "http://localhost:9100/metrics" "node-exporter"
    fi
elif podman ps --format "{{.Names}}" | grep -q "pcp-exporter"; then
    check_service "PCP Exporter" "http://localhost:44323/metrics" "pcp-exporter"
else
    echo -e "${YELLOW}No exporter container found${NC}"
    echo ""
fi

# Check Prometheus targets
echo -e "${BLUE}Prometheus Targets:${NC}"

if [ "$AUTH_REQUIRED" = true ]; then
    # Use basic auth for API calls
    targets=$(curl -s --max-time 5 -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" http://localhost:9090/api/v1/targets 2>/dev/null || echo '{"status":"error"}')
else
    targets=$(curl -s --max-time 5 http://localhost:9090/api/v1/targets 2>/dev/null || echo '{"status":"error"}')
fi
status=$(echo "$targets" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$status" = "success" ]; then
    active_targets=$(echo "$targets" | jq -r '.data.activeTargets[]' 2>/dev/null || echo '[]')
    
    if [ -n "$active_targets" ] && [ "$active_targets" != "[]" ]; then
        echo "$active_targets" | jq -r '. | "  - Job: \(.labels.job), Instance: \(.labels.instance), State: \(if .health == "up" then "✅ UP" else "❌ DOWN" end), Last Scrape: \(.lastScrape | sub("\\.[0-9]+Z$"; "Z") | strptime("%Y-%m-%dT%H:%M:%SZ") | strftime("%Y-%m-%d %H:%M:%S"))"' 2>/dev/null || \
        echo "$active_targets" | jq -r '. | "  - Job: \(.labels.job), Instance: \(.labels.instance), State: \(if .health == "up" then "✅ UP" else "❌ DOWN" end)"'
    else
        echo "  No active targets"
    fi
else
    echo -e "  ${RED}❌ Could not retrieve targets${NC}"
fi

echo ""

# Check disk usage for Prometheus data
echo -e "${BLUE}Storage:${NC}"
if podman volume exists prometheus-data 2>/dev/null; then
    # Get volume info
    volume_path=$(podman volume inspect prometheus-data --format '{{.Mountpoint}}' 2>/dev/null || echo "")
    
    if [ -n "$volume_path" ] && [ -d "$volume_path" ]; then
        # Get disk usage
        usage=$(du -sh "$volume_path" 2>/dev/null | cut -f1 || echo "Unknown")
        echo "  Prometheus data volume: $usage"
        
        # Get number of series
        if [ "$AUTH_REQUIRED" = true ]; then
            CURL_AUTH="-u ${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}"
        else
            CURL_AUTH=""
        fi
        
        if [ "$AUTH_REQUIRED" = true ]; then
            if curl -s --max-time 5 -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes' &>/dev/null; then
                series_count=$(curl -s --max-time 5 -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series' | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
                samples_count=$(curl -s --max-time 5 -u "${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}" 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_samples' | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
            else
                series_count="0"
                samples_count="0"
            fi
        else
            if curl -s --max-time 5 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes' &>/dev/null; then
                series_count=$(curl -s --max-time 5 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_series' | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
                samples_count=$(curl -s --max-time 5 'http://localhost:9090/api/v1/query?query=prometheus_tsdb_head_samples' | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
            else
                series_count="0"
                samples_count="0"
            fi
        fi
            
        if [ "$series_count" != "0" ]; then
            echo "  Time series: $series_count"
            echo "  Total samples: $samples_count"
        fi
    else
        echo "  Prometheus data volume exists but path not accessible"
    fi
else
    echo "  No Prometheus data volume found"
fi

echo ""

# Network information
echo -e "${BLUE}Network:${NC}"
network_info=$(podman network ls --filter name=prom-dev_monitoring --format "{{.Name}}: {{.Subnets}}" 2>/dev/null || echo "")
if [ -n "$network_info" ]; then
    echo "  $network_info"
else
    echo "  No dedicated network found"
fi

echo ""

# Resource usage
echo -e "${BLUE}Resource Usage:${NC}"
# First try by label, then fall back to name pattern
containers_by_label=$(podman ps --filter "label=project=prom-dev" --format "{{.Names}}" 2>/dev/null || echo "")
if [ -z "$containers_by_label" ]; then
    containers=$(podman ps --format "{{.Names}}" 2>/dev/null | grep -E "(prometheus-dev|node-exporter|pcp-exporter|prometheus-auth-proxy)" || echo "")
else
    containers="$containers_by_label"
fi

if [ -n "$containers" ]; then
    for container in $containers; do
        stats=$(podman stats --no-stream --format "{{.Container}}: CPU {{.CPUPerc}}, Memory {{.MemUsage}} ({{.MemPerc}})" "$container" 2>/dev/null || echo "$container: Unable to get stats")
        echo "  $stats"
    done
else
    echo "  No running containers found"
fi

echo ""
echo "💡 Tips:"
echo "  - View logs: ./scripts/logs.sh [container-name]"
echo "  - Run tests: ./scripts/test.sh"
echo "  - Access Prometheus UI: http://localhost:9090"
echo ""
