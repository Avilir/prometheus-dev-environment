#!/bin/bash
# Generate htpasswd file for Nginx authentication
# Author: Avi Layani
# Purpose: Create users for Prometheus authentication from credentials file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
HTPASSWD_FILE="$SCRIPT_DIR/.htpasswd"
CREDS_FILE="$PROJECT_DIR/configs/credentials.env"

echo "🔐 Generating htpasswd file for Prometheus authentication..."
echo "========================================================="

# Check if credentials file exists
if [ ! -f "$CREDS_FILE" ]; then
    echo "❌ ERROR: Credentials file not found: $CREDS_FILE"
    echo ""
    echo "📝 To set up credentials:"
    echo "   1. cp configs/credentials.env.example configs/credentials.env"
    echo "   2. Edit configs/credentials.env with secure passwords"
    echo "   3. chmod 600 configs/credentials.env"
    echo ""
    echo "⚠️  SECURITY WARNING: Never use default values in production!"
    exit 1
fi

# Load credentials
source "$CREDS_FILE"

# Validate required variables
if [ -z "$PROM_ADMIN_PASS" ] || [ "$PROM_ADMIN_PASS" == "CHANGE_ME_ADMIN_PASSWORD" ]; then
    echo "❌ ERROR: PROM_ADMIN_PASS not set or still has default value!"
    echo "   Please edit configs/credentials.env with secure passwords"
    exit 1
fi

# Check if htpasswd is available
if ! command -v htpasswd &> /dev/null; then
    echo "⚠️  htpasswd not found. Installing httpd-tools..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y httpd-tools
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y apache2-utils
    else
        echo "❌ Could not install htpasswd. Please install manually."
        exit 1
    fi
fi

# Create htpasswd file with users from credentials
echo ""
echo "📝 Creating users from configs/credentials.env..."

# Admin user (full access)
echo "  - Creating user: $PROM_ADMIN_USER"
htpasswd -cb "$HTPASSWD_FILE" "$PROM_ADMIN_USER" "$PROM_ADMIN_PASS"

# Prometheus user (standard access)
if [ -n "$PROM_USER_USER" ] && [ -n "$PROM_USER_PASS" ]; then
    echo "  - Creating user: $PROM_USER_USER"
    htpasswd -b "$HTPASSWD_FILE" "$PROM_USER_USER" "$PROM_USER_PASS"
fi

# Read-only user
if [ -n "$PROM_VIEWER_USER" ] && [ -n "$PROM_VIEWER_PASS" ]; then
    echo "  - Creating user: $PROM_VIEWER_USER"
    htpasswd -b "$HTPASSWD_FILE" "$PROM_VIEWER_USER" "$PROM_VIEWER_PASS"
fi

# Test user
if [ -n "$PROM_TEST_USER" ] && [ -n "$PROM_TEST_PASS" ]; then
    echo "  - Creating user: $PROM_TEST_USER"
    htpasswd -b "$HTPASSWD_FILE" "$PROM_TEST_USER" "$PROM_TEST_PASS"
fi

# Set appropriate permissions
chmod 644 "$HTPASSWD_FILE"

echo ""
echo "✅ htpasswd file created at: $HTPASSWD_FILE"
echo ""
echo "🔒 Security Notes:"
echo "=================="
echo "  - Passwords loaded from: configs/credentials.env"
echo "  - Basic Auth users created: $(wc -l < "$HTPASSWD_FILE") users"
echo "  - Bearer Token: Configured in nginx.conf"
echo "  - API Token: Configured in nginx.conf"
echo ""
echo "📋 To view configured users:"
echo "   cat $HTPASSWD_FILE | cut -d: -f1"
echo ""
echo "⚠️  REMINDER: Keep configs/credentials.env secure and never commit it!"