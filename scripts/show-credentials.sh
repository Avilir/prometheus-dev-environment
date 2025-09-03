#!/bin/bash
# Script to load authentication credentials from centralized config
# Author: Avi Layani
# Purpose: Set environment variables for authentication testing

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh" || { echo "Failed to load common library"; exit 1; }

PROJECT_DIR="$(get_project_dir)"
CREDS_FILE="${PROJECT_DIR}/configs/credentials.env"

echo "🔐 Loading authentication credentials..."
echo "========================================"
echo ""

# Check if credentials file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ ERROR: Credentials file not found: $CREDS_FILE"
    echo ""
    echo "📝 To set up credentials:"
    echo "   1. cp configs/credentials.env.example configs/credentials.env"
    echo "   2. Edit configs/credentials.env with secure values"
    echo "   3. chmod 600 configs/credentials.env"
    echo ""
    echo "⚠️  SECURITY: Never use default values from the example file!"
    return 1 2>/dev/null || exit 1
fi

# Load credentials
source "$CREDS_FILE"

# Export for auth testing (using admin credentials by default)
export PROM_BASIC_USER="${PROM_ADMIN_USER}"
export PROM_BASIC_PASS="${PROM_ADMIN_PASS}"

echo "✅ Environment variables loaded from: configs/credentials.env"
echo "   PROM_BASIC_USER=$PROM_BASIC_USER"
echo "   PROM_BASIC_PASS=******"
echo "   PROM_BEARER_TOKEN=******"
echo "   PROM_API_TOKEN=******"
echo ""
echo "💡 To use these credentials:"
echo "   source ./scripts/test-credentials.sh"
echo "   ./scripts/test-auth.sh"
echo ""
echo "🔒 Security: Using credentials from configs/credentials.env"