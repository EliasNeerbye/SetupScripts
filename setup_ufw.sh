#!/bin/bash

# UFW Firewall Setup Script
# Interactive configuration of UFW firewall rules

set -e  # Exit on any error

echo "🔥 UFW Firewall Setup Script"
echo "=============================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Function to ask yes/no questions
ask_yes_no() {
    local prompt="$1"
    local response
    while true; do
        read -r -p "$prompt (y/n): " response
        case $response in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

# Function to get IP address input
get_ip_input() {
    local prompt="$1"
    local ip_address
    while true; do
        read -r -p "$prompt: " ip_address
        if [[ $ip_address =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip_address"
            return 0
        else
            echo "❌ Invalid IP format. Please use format: 192.168.1.100"
        fi
    done
}

echo ""
echo "🚀 Starting UFW configuration..."

# Reset UFW to clean state
echo "🔄 Resetting UFW to default state..."
ufw --force reset

# Set default policies
echo "🛡️  Setting default policies..."
ufw default deny incoming
ufw default deny outgoing

echo ""
echo "📋 Service Configuration"
echo "========================"

# SSH Configuration
if ask_yes_no "🔐 Enable SSH access (port 22)?"; then
    ufw allow in 22/tcp
    echo "✅ SSH (port 22) enabled for incoming connections"
fi

# Nginx Configuration
if ask_yes_no "🌐 Enable Nginx (HTTP/HTTPS ports 80,443)?"; then
    ufw allow in 'Nginx Full'
    echo "✅ Nginx Full profile enabled for incoming connections"
fi

# MongoDB Configuration
if ask_yes_no "🍃 Enable MongoDB access (port 27017)?"; then
    if ask_yes_no "   Restrict MongoDB to specific IP?"; then
        mongo_ip=$(get_ip_input "   Enter IP address for MongoDB access")
        ufw allow in from "$mongo_ip" to any port 27017
        echo "✅ MongoDB (port 27017) enabled from $mongo_ip"
        
        # Ask if we should allow outbound to the same IP
        if ask_yes_no "   Allow outbound MongoDB connections to $mongo_ip?"; then
            ufw allow out to "$mongo_ip" port 27017
            echo "✅ Outbound MongoDB to $mongo_ip enabled"
        fi
    else
        ufw allow in 27017
        echo "✅ MongoDB (port 27017) enabled from anywhere"
    fi
fi

echo ""
echo "🌍 Outbound Connection Configuration"
echo "===================================="

# HTTP/HTTPS Outbound
if ask_yes_no "🔗 Allow outbound HTTP connections (port 80)?"; then
    ufw allow out 80/tcp
    echo "✅ Outbound HTTP (port 80) enabled"
fi

if ask_yes_no "🔒 Allow outbound HTTPS connections (port 443)?"; then
    ufw allow out 443/tcp
    echo "✅ Outbound HTTPS (port 443) enabled"
fi

# DNS Outbound
if ask_yes_no "🔍 Allow outbound DNS queries (port 53)?"; then
    ufw allow out 53
    echo "✅ Outbound DNS (port 53) enabled"
fi

# Custom rules
echo ""
if ask_yes_no "➕ Add any custom rules?"; then
    while true; do
        echo ""
        echo "Custom rule options:"
        echo "1. Allow incoming port"
        echo "2. Allow outgoing port"
        echo "3. Allow incoming from specific IP"
        echo "4. Allow outgoing to specific IP"
        echo "5. Done with custom rules"
        
        read -r -p "Choose option (1-5): " option
        
        case $option in
            1)
                read -r -p "Enter port number: " port
                ufw allow in "$port"
                echo "✅ Incoming port $port allowed"
                ;;
            2)
                read -r -p "Enter port number: " port
                ufw allow out "$port"
                echo "✅ Outgoing port $port allowed"
                ;;
            3)
                custom_ip=$(get_ip_input "Enter IP address")
                read -r -p "Enter port (or press Enter for all): " port
                if [ -n "$port" ]; then
                    ufw allow in from "$custom_ip" to any port "$port"
                    echo "✅ Incoming from $custom_ip to port $port allowed"
                else
                    ufw allow in from "$custom_ip"
                    echo "✅ All incoming from $custom_ip allowed"
                fi
                ;;
            4)
                custom_ip=$(get_ip_input "Enter IP address")
                read -r -p "Enter port (or press Enter for all): " port
                if [ -n "$port" ]; then
                    ufw allow out to "$custom_ip" port "$port"
                    echo "✅ Outgoing to $custom_ip port $port allowed"
                else
                    ufw allow out to "$custom_ip"
                    echo "✅ All outgoing to $custom_ip allowed"
                fi
                ;;
            5)
                break
                ;;
            *)
                echo "❌ Invalid option. Please choose 1-5."
                ;;
        esac
    done
fi

# Enable UFW
echo ""
echo "🔥 Enabling UFW firewall..."
ufw --force enable

# Show final status
echo ""
echo "🎉 UFW Configuration Complete!"
echo "=============================="
echo ""
echo "📊 Current UFW Status:"
ufw status verbose

echo ""
echo "💡 Useful commands:"
echo "   • View status: sudo ufw status verbose"
echo "   • Disable UFW: sudo ufw disable"
echo "   • Reset UFW: sudo ufw --force reset"
echo "   • Add rule: sudo ufw allow [port/service]"
echo "   • Remove rule: sudo ufw delete [rule]"
