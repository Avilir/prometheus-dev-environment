#!/bin/bash
# Load credentials from centralized configuration
# Source this file to get authentication credentials

# Get the directory of this script
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$LIB_DIR/../.." && pwd)"
CREDS_FILE="$PROJECT_DIR/configs/credentials.env"

# Check if credentials file exists
if [ ! -f "$CREDS_FILE" ]; then
    # If running in non-interactive mode or credentials not required, use empty values
    if [ "$REQUIRE_CREDENTIALS" = "true" ]; then
        echo "❌ ERROR: Credentials required but not found: $CREDS_FILE" >&2
        echo "   Run: cp configs/credentials.env.example configs/credentials.env" >&2
        echo "   Then edit with secure values" >&2
        return 1 2>/dev/null || exit 1
    else
        # Set empty/default values for scripts that may not need auth
        export PROM_ADMIN_USER=""
        export PROM_ADMIN_PASS=""
        export PROM_BEARER_TOKEN=""
        export PROM_API_TOKEN=""
        return 0
    fi
fi

# Load credentials
source "$CREDS_FILE"

# Export commonly used combinations
export PROM_BASIC_AUTH="${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}"

# Function to get curl auth args
get_curl_auth() {
    if [ -n "$PROM_ADMIN_USER" ] && [ -n "$PROM_ADMIN_PASS" ]; then
        echo "-u ${PROM_ADMIN_USER}:${PROM_ADMIN_PASS}"
    else
        echo ""
    fi
}
