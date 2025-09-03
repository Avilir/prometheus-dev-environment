#!/bin/bash
# Comprehensive test script for Prometheus Development Environment
# Author: Avi Layani
# Purpose: Test connectivity, authentication, data collection, and queries

set -e

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"

# Default values
PROMETHEUS_URL="http://localhost:9090"
VERBOSE=false
TEST_QUERY="up"

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Test authentication methods and data collection for Prometheus"
    echo ""
    echo "This script tests:"
    echo "  - Various authentication methods (Basic, Bearer, API Token)"
    echo "  - Prometheus data collection and metric availability"
    echo "  - Node Exporter metrics (if available)"
    echo "  - Advanced PromQL queries"
    echo "  - Time series statistics"
    echo ""
    echo "Options:"
    echo "  -u, --url URL          Prometheus URL (default: http://localhost:9090)"
    echo "  -q, --query QUERY      Test query (default: 'up')"
    echo "  -v, --verbose          Show detailed output"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Environment variables for auth testing:"
    echo "  PROM_BEARER_TOKEN      Bearer token for authentication"
    echo "  PROM_BASIC_USER        Basic auth username"
    echo "  PROM_BASIC_PASS        Basic auth password"
    echo "  PROM_API_TOKEN         API token for token-based auth"
    echo ""
    echo "Examples:"
    echo "  # Test local Prometheus without auth"
    echo "  $0"
    echo ""
    echo "  # Test remote Prometheus"
    echo "  $0 -u http://prometheus.example.com:9090"
    echo ""
    echo "  # Test with bearer token"
    echo "  PROM_BEARER_TOKEN='your-token' $0"
    echo ""
    echo "  # Test with basic auth"
    echo "  PROM_BASIC_USER='admin' PROM_BASIC_PASS='password' $0"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--url)
            PROMETHEUS_URL="$2"
            shift 2
            ;;
        -q|--query)
            TEST_QUERY="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

echo "🔐 Prometheus Authentication Test"
echo "================================="
echo ""
echo "Target URL: $PROMETHEUS_URL"
echo "Test Query: $TEST_QUERY"
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Function to test connection
test_connection() {
    local test_name="$1"
    local curl_args="$2"
    local expected_success="$3"  # true or false
    
    echo -e "${BLUE}Testing: $test_name${NC}"
    
    # Build the full curl command
    local cmd="curl -s -w '\n%{http_code}' $curl_args '${PROMETHEUS_URL}/api/v1/query?query=${TEST_QUERY}'"
    
    if [ "$VERBOSE" = true ]; then
        echo "  Command: $cmd"
    fi
    
    # Execute the command
    local response
    response=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    # Extract HTTP status code (last line)
    local http_code=$(echo "$response" | tail -n1)
    local body=$(echo "$response" | head -n-1)
    
    # Check if it's a valid HTTP response
    if ! [[ "$http_code" =~ ^[0-9]+$ ]]; then
        echo -e "  ${RED}❌ FAILED${NC} - No valid HTTP response"
        if [ "$VERBOSE" = true ]; then
            echo "  Response: $response"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return
    fi
    
    # Determine success based on HTTP code
    local success=false
    if [[ "$http_code" -ge 200 && "$http_code" -lt 300 ]]; then
        success=true
    fi
    
    # Check if result matches expectation
    if [ "$success" = "$expected_success" ]; then
        if [ "$success" = true ]; then
            echo -e "  ${GREEN}✅ PASSED${NC} - HTTP $http_code"
            
            # Parse and show result if successful
            if [ "$VERBOSE" = true ] && [ "$http_code" = "200" ]; then
                local result_count=$(echo "$body" | jq -r '.data.result | length' 2>/dev/null || echo "0")
                echo "  Results: $result_count entries"
            fi
        else
            echo -e "  ${GREEN}✅ PASSED${NC} - Correctly rejected with HTTP $http_code"
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}❌ FAILED${NC} - HTTP $http_code (expected ${expected_success})"
        if [ "$VERBOSE" = true ]; then
            echo "  Response body: $body"
        fi
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    
    echo ""
}

# 1. Test without authentication
echo "1️⃣  No Authentication Test"
echo "-------------------------"
test_connection "No auth" "" "true"

# 2. Test with Bearer token
if [ -n "$PROM_BEARER_TOKEN" ]; then
    echo "2️⃣  Bearer Token Authentication Test"
    echo "-----------------------------------"
    test_connection "Valid bearer token" "-H 'Authorization: Bearer $PROM_BEARER_TOKEN'" "true"
    test_connection "Invalid bearer token" "-H 'Authorization: Bearer invalid-token-12345'" "false"
else
    echo "2️⃣  Bearer Token Authentication Test"
    echo "-----------------------------------"
    echo -e "  ${YELLOW}⚠️  SKIPPED${NC} - Set PROM_BEARER_TOKEN environment variable to test"
    echo ""
fi

# 3. Test with Basic authentication
if [ -n "$PROM_BASIC_USER" ] && [ -n "$PROM_BASIC_PASS" ]; then
    echo "3️⃣  Basic Authentication Test"
    echo "----------------------------"
    test_connection "Valid credentials" "-u '$PROM_BASIC_USER:$PROM_BASIC_PASS'" "true"
    test_connection "Invalid credentials" "-u 'wronguser:wrongpass'" "false"
else
    echo "3️⃣  Basic Authentication Test"
    echo "----------------------------"
    echo -e "  ${YELLOW}⚠️  SKIPPED${NC} - Set PROM_BASIC_USER and PROM_BASIC_PASS to test"
    echo ""
fi

# 4. Test with API Token (custom header)
if [ -n "$PROM_API_TOKEN" ]; then
    echo "4️⃣  API Token Authentication Test"
    echo "--------------------------------"
    test_connection "Valid API token" "-H 'X-API-Token: $PROM_API_TOKEN'" "true"
    test_connection "Invalid API token" "-H 'X-API-Token: invalid-api-token'" "false"
else
    echo "4️⃣  API Token Authentication Test"
    echo "--------------------------------"
    echo -e "  ${YELLOW}⚠️  SKIPPED${NC} - Set PROM_API_TOKEN environment variable to test"
    echo ""
fi

# 5. Test various endpoints
echo "5️⃣  Endpoint Tests"
echo "-----------------"

# Test metrics endpoint
echo -e "${BLUE}Testing: Metrics endpoint${NC}"
http_code=$(curl -s -o /dev/null -w "%{http_code}" "${PROMETHEUS_URL}/metrics")
if [ "$http_code" = "200" ]; then
    echo -e "  ${GREEN}✅ PASSED${NC} - HTTP $http_code"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}❌ FAILED${NC} - HTTP $http_code"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test health endpoint
echo -e "${BLUE}Testing: Health endpoint${NC}"
http_code=$(curl -s -o /dev/null -w "%{http_code}" "${PROMETHEUS_URL}/-/healthy")
if [ "$http_code" = "200" ]; then
    echo -e "  ${GREEN}✅ PASSED${NC} - HTTP $http_code"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}❌ FAILED${NC} - HTTP $http_code"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test ready endpoint
echo -e "${BLUE}Testing: Ready endpoint${NC}"
http_code=$(curl -s -o /dev/null -w "%{http_code}" "${PROMETHEUS_URL}/-/ready")
if [ "$http_code" = "200" ]; then
    echo -e "  ${GREEN}✅ PASSED${NC} - HTTP $http_code"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}❌ FAILED${NC} - HTTP $http_code"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# 6. Test Data Collection and Queries
echo "6️⃣  Data Collection Tests"
echo "------------------------"

# Function to test Prometheus queries
test_query() {
    local query_name="$1"
    local query="$2"
    local expected_min_results="${3:-1}"  # Default expect at least 1 result
    local auth_args=""
    
    # Use appropriate auth based on what's configured
    if [ -n "$PROM_BASIC_USER" ] && [ -n "$PROM_BASIC_PASS" ]; then
        auth_args="-u '$PROM_BASIC_USER:$PROM_BASIC_PASS'"
    elif [ -n "$PROM_BEARER_TOKEN" ]; then
        auth_args="-H 'Authorization: Bearer $PROM_BEARER_TOKEN'"
    elif [ -n "$PROM_API_TOKEN" ]; then
        auth_args="-H 'X-API-Token: $PROM_API_TOKEN'"
    fi
    
    echo -e "${BLUE}Testing: $query_name${NC}"
    if [ "$VERBOSE" = true ]; then
        echo "  Query: $query"
    fi
    
    # Execute the query
    local cmd="curl -s $auth_args '${PROMETHEUS_URL}/api/v1/query?query=$(echo "$query" | jq -sRr @uri)'"
    local response=$(eval "$cmd" 2>&1)
    local exit_code=$?
    
    # Check if we got a valid response
    local status=$(echo "$response" | jq -r '.status' 2>/dev/null || echo "error")
    
    if [ "$status" = "success" ]; then
        local result_count=$(echo "$response" | jq -r '.data.result | length' 2>/dev/null || echo "0")
        
        if [ "$result_count" -ge "$expected_min_results" ]; then
            echo -e "  ${GREEN}✅ PASSED${NC} - Found $result_count results"
            
            # Show sample values if verbose
            if [ "$VERBOSE" = true ] && [ "$result_count" -gt 0 ]; then
                echo "$response" | jq -r '.data.result[0] | "    Sample: \(.metric | to_entries | map("\(.key)=\"\(.value)\"") | join(", ")) = \(.value[1])"' 2>/dev/null || true
            fi
            
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  ${RED}❌ FAILED${NC} - Expected at least $expected_min_results results, got $result_count"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        echo -e "  ${RED}❌ FAILED${NC} - Query error: $(echo "$response" | jq -r '.error // "Unknown error"' 2>/dev/null || echo "$response")"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    echo ""
}

# Test basic connectivity metric
test_query "Up metric (all targets)" "up" 2

# Test Prometheus self-monitoring metrics
test_query "Prometheus build info" "prometheus_build_info" 1
test_query "Prometheus scrape duration" "prometheus_target_scrape_duration_seconds" 1
test_query "Prometheus TSDB head series" "prometheus_tsdb_head_series" 1

# Test Node Exporter metrics (if available)
echo "7️⃣  Node Exporter Metrics Tests"
echo "-------------------------------"

# Build auth args for node exporter check
auth_args=""
if [ -n "$PROM_BASIC_USER" ] && [ -n "$PROM_BASIC_PASS" ]; then
    auth_args="-u '$PROM_BASIC_USER:$PROM_BASIC_PASS'"
elif [ -n "$PROM_BEARER_TOKEN" ]; then
    auth_args="-H 'Authorization: Bearer $PROM_BEARER_TOKEN'"
elif [ -n "$PROM_API_TOKEN" ]; then
    auth_args="-H 'X-API-Token: $PROM_API_TOKEN'"
fi

# Check if node exporter is running
node_response=$(eval "curl -s $auth_args '${PROMETHEUS_URL}/api/v1/query?query=up%7Bjob%3D%22node-exporter%22%7D'" 2>/dev/null)
node_exporter_up=$(echo "$node_response" | jq -r '.data.result[0].value[1] // "0"' 2>/dev/null || echo "0")

if [ "$node_exporter_up" = "1" ]; then
    test_query "CPU usage" "rate(node_cpu_seconds_total[5m])" 1
    test_query "Memory usage" "node_memory_MemAvailable_bytes" 1
    test_query "Disk usage" "node_filesystem_avail_bytes" 1
    test_query "Load average" "node_load1" 1
    test_query "Network traffic" "rate(node_network_receive_bytes_total[5m])" 1
else
    echo -e "  ${YELLOW}⚠️  Node Exporter not available or not up${NC}"
    echo ""
fi

# Test advanced queries
echo "8️⃣  Advanced Query Tests"
echo "-----------------------"

# Test aggregation queries
test_query "Average CPU usage" "avg(rate(node_cpu_seconds_total[5m]))" 0
test_query "Memory usage percentage" "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100" 0
test_query "Filesystem usage over 80%" "node_filesystem_avail_bytes / node_filesystem_size_bytes < 0.2" 0

# Test metric metadata
echo "9️⃣  Metadata Tests"
echo "-----------------"

echo -e "${BLUE}Testing: Label values for 'job' label${NC}"
label_response=$(eval "curl -s $auth_args '${PROMETHEUS_URL}/api/v1/label/job/values'" 2>&1)
label_status=$(echo "$label_response" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$label_status" = "success" ]; then
    job_count=$(echo "$label_response" | jq -r '.data | length' 2>/dev/null || echo "0")
    if [ "$job_count" -gt 0 ]; then
        echo -e "  ${GREEN}✅ PASSED${NC} - Found $job_count job labels"
        if [ "$VERBOSE" = true ]; then
            echo "$label_response" | jq -r '.data[] | "    - \(.)"' 2>/dev/null || true
        fi
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}❌ FAILED${NC} - No job labels found"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "  ${RED}❌ FAILED${NC} - Could not retrieve label values"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Test time series statistics
echo -e "${BLUE}Testing: Time series statistics${NC}"
stats_cmd="curl -s $auth_args '${PROMETHEUS_URL}/api/v1/query?query=prometheus_tsdb_symbol_table_size_bytes'"
stats_response=$(eval "$stats_cmd" 2>&1)
stats_status=$(echo "$stats_response" | jq -r '.status' 2>/dev/null || echo "error")

if [ "$stats_status" = "success" ]; then
    echo -e "  ${GREEN}✅ PASSED${NC} - TSDB is collecting data"
    
    # Get more detailed stats if verbose
    if [ "$VERBOSE" = true ]; then
        series_count=$(eval "curl -s $auth_args '${PROMETHEUS_URL}/api/v1/query?query=prometheus_tsdb_head_series'" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        samples_count=$(eval "curl -s $auth_args '${PROMETHEUS_URL}/api/v1/query?query=prometheus_tsdb_head_samples'" | jq -r '.data.result[0].value[1]' 2>/dev/null || echo "0")
        echo "    Time series: $series_count"
        echo "    Total samples: $samples_count"
    fi
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}❌ FAILED${NC} - TSDB metrics not available"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
echo ""

# Summary
echo "📊 Test Summary"
echo "==============="
echo -e "Tests Passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests Failed: ${RED}$TESTS_FAILED${NC}"
echo ""

# Show example configurations
echo "💡 Authentication Configuration Examples"
echo "======================================"
echo ""
echo "Since Prometheus doesn't have built-in auth, use a reverse proxy:"
echo ""
echo "1. Nginx with Basic Auth:"
echo "   location /prometheus/ {"
echo "     auth_basic \"Prometheus\";"
echo "     auth_basic_user_file /etc/nginx/.htpasswd;"
echo "     proxy_pass http://localhost:9090/;"
echo "   }"
echo ""
echo "2. Nginx with Bearer Token:"
echo "   location /prometheus/ {"
echo "     if (\$http_authorization != \"Bearer your-secret-token\") {"
echo "       return 403;"
echo "     }"
echo "     proxy_pass http://localhost:9090/;"
echo "   }"
echo ""
echo "3. Apache with Basic Auth:"
echo "   <Location /prometheus>"
echo "     AuthType Basic"
echo "     AuthName \"Prometheus\""
echo "     AuthUserFile /etc/apache2/.htpasswd"
echo "     Require valid-user"
echo "     ProxyPass http://localhost:9090/"
echo "   </Location>"

if [ $TESTS_FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
