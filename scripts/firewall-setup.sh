#!/bin/bash
# Firewall setup script for Prometheus development environment
# Author: Avi Layani
# Purpose: Configure firewall rules for external access

set -e

echo "🔥 Configuring Firewall for Prometheus Access"
echo "============================================="
echo ""

# Check if running as root/sudo
if [ "$EUID" -ne 0 ]; then
   echo "❌ This script must be run with sudo"
   echo "   Usage: sudo $0"
   exit 1
fi

# Check which firewall is being used
if command -v firewall-cmd &> /dev/null; then
    echo "📋 Detected firewalld"
    FIREWALL_TYPE="firewalld"
elif command -v ufw &> /dev/null; then
    echo "📋 Detected ufw"
    FIREWALL_TYPE="ufw"
else
    echo "❌ No supported firewall detected (firewalld or ufw)"
    exit 1
fi

# Function to open ports with firewalld
open_ports_firewalld() {
    echo ""
    echo "🔧 Opening ports with firewalld..."
    
    # Open Prometheus port
    echo "  - Opening port 9090/tcp (Prometheus)..."
    firewall-cmd --permanent --add-port=9090/tcp
    
    # Open Node Exporter port (if needed)
    echo "  - Opening port 9100/tcp (Node Exporter)..."
    firewall-cmd --permanent --add-port=9100/tcp
    
    # Open PCP port (if needed)
    echo "  - Opening port 44323/tcp (PCP Exporter)..."
    firewall-cmd --permanent --add-port=44323/tcp
    
    # Reload firewall
    echo "  - Reloading firewall..."
    firewall-cmd --reload
    
    echo ""
    echo "✅ Firewall rules added successfully!"
    echo ""
    echo "📊 Current open ports:"
    firewall-cmd --list-ports
}

# Function to open ports with ufw
open_ports_ufw() {
    echo ""
    echo "🔧 Opening ports with ufw..."
    
    # Open Prometheus port
    echo "  - Opening port 9090/tcp (Prometheus)..."
    ufw allow 9090/tcp
    
    # Open Node Exporter port (if needed)
    echo "  - Opening port 9100/tcp (Node Exporter)..."
    ufw allow 9100/tcp
    
    # Open PCP port (if needed)
    echo "  - Opening port 44323/tcp (PCP Exporter)..."
    ufw allow 44323/tcp
    
    echo ""
    echo "✅ Firewall rules added successfully!"
    echo ""
    echo "📊 Current status:"
    ufw status
}

# Function to show how to restrict access
show_security_tips() {
    echo ""
    echo "🔒 Security Tips:"
    echo "=================="
    
    if [ "$FIREWALL_TYPE" = "firewalld" ]; then
        echo ""
        echo "To restrict access to specific IP addresses only:"
        echo ""
        echo "  # Remove the open port:"
        echo "  sudo firewall-cmd --permanent --remove-port=9090/tcp"
        echo ""
        echo "  # Add rich rule for specific IP:"
        echo "  sudo firewall-cmd --permanent --add-rich-rule='rule family=\"ipv4\" source address=\"192.168.1.100/32\" port protocol=\"tcp\" port=\"9090\" accept'"
        echo ""
        echo "  # Reload firewall:"
        echo "  sudo firewall-cmd --reload"
    elif [ "$FIREWALL_TYPE" = "ufw" ]; then
        echo ""
        echo "To restrict access to specific IP addresses only:"
        echo ""
        echo "  # Remove the open port:"
        echo "  sudo ufw delete allow 9090/tcp"
        echo ""
        echo "  # Add rule for specific IP:"
        echo "  sudo ufw allow from 192.168.1.100 to any port 9090"
    fi
    
    echo ""
    echo "To remove access later:"
    if [ "$FIREWALL_TYPE" = "firewalld" ]; then
        echo "  sudo firewall-cmd --permanent --remove-port=9090/tcp"
        echo "  sudo firewall-cmd --permanent --remove-port=9100/tcp"
        echo "  sudo firewall-cmd --permanent --remove-port=44323/tcp"
        echo "  sudo firewall-cmd --reload"
    elif [ "$FIREWALL_TYPE" = "ufw" ]; then
        echo "  sudo ufw delete allow 9090/tcp"
        echo "  sudo ufw delete allow 9100/tcp"
        echo "  sudo ufw delete allow 44323/tcp"
    fi
}

# Main execution
case "$FIREWALL_TYPE" in
    firewalld)
        open_ports_firewalld
        ;;
    ufw)
        open_ports_ufw
        ;;
esac

show_security_tips

echo ""
echo "📌 Test from another host:"
echo "   curl http://$(hostname -I | awk '{print $1}'):9090/-/healthy"
echo "   firefox http://$(hostname -I | awk '{print $1}'):9090"
echo ""
