#!/bin/bash

set -e

echo "UFW Firewall Setup"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Helper functions
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

get_ip_input() {
    local prompt="$1"
    local ip_address
    while true; do
        read -r -p "$prompt: " ip_address
        if [[ $ip_address =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip_address"
            return 0
        else
            echo "Invalid IP format. Use: 192.168.1.100"
        fi
    done
}

# Reset UFW and set defaults
echo "Resetting UFW..."
ufw --force reset
ufw default deny incoming
ufw default deny outgoing

# Configure services
echo ""
echo "Service Configuration:"

# SSH
if ask_yes_no "Enable SSH access (port 22)?"; then
    ufw allow in 22/tcp
    echo "SSH enabled"
fi

# Nginx
if ask_yes_no "Enable Nginx (HTTP/HTTPS)?"; then
    ufw allow in 'Nginx Full'
    echo "Nginx enabled"
fi

# MongoDB
if ask_yes_no "Enable MongoDB access (port 27017)?"; then
    if ask_yes_no "Restrict MongoDB to specific IP?"; then
        mongo_ip=$(get_ip_input "Enter IP for MongoDB access")
        ufw allow in from "$mongo_ip" to any port 27017
        echo "MongoDB enabled from $mongo_ip"
        
        if ask_yes_no "Allow outbound MongoDB to $mongo_ip?"; then
            ufw allow out to "$mongo_ip" port 27017
            echo "Outbound MongoDB to $mongo_ip enabled"
        fi
    else
        ufw allow in 27017
        echo "MongoDB enabled from anywhere"
    fi
fi

# Outbound connections
echo ""
echo "Outbound Configuration:"

if ask_yes_no "Allow outbound HTTP (port 80)?"; then
    ufw allow out 80/tcp
    echo "Outbound HTTP enabled"
fi

if ask_yes_no "Allow outbound HTTPS (port 443)?"; then
    ufw allow out 443/tcp
    echo "Outbound HTTPS enabled"
fi

if ask_yes_no "Allow outbound DNS (port 53)?"; then
    ufw allow out 53
    echo "Outbound DNS enabled"
fi

# Custom rules
if ask_yes_no "Add custom rules?"; then
    while true; do
        echo ""
        echo "1. Allow incoming port"
        echo "2. Allow outgoing port"  
        echo "3. Allow incoming from IP"
        echo "4. Allow outgoing to IP"
        echo "5. Done"
        
        read -r -p "Choose (1-5): " option
        
        case $option in
            1)
                read -r -p "Port: " port
                ufw allow in "$port"
                echo "Incoming port $port allowed"
                ;;
            2)
                read -r -p "Port: " port
                ufw allow out "$port"
                echo "Outgoing port $port allowed"
                ;;
            3)
                custom_ip=$(get_ip_input "IP address")
                read -r -p "Port (or Enter for all): " port
                if [ -n "$port" ]; then
                    ufw allow in from "$custom_ip" to any port "$port"
                    echo "Incoming from $custom_ip:$port allowed"
                else
                    ufw allow in from "$custom_ip"
                    echo "All incoming from $custom_ip allowed"
                fi
                ;;
            4)
                custom_ip=$(get_ip_input "IP address")
                read -r -p "Port (or Enter for all): " port
                if [ -n "$port" ]; then
                    ufw allow out to "$custom_ip" port "$port"
                    echo "Outgoing to $custom_ip:$port allowed"
                else
                    ufw allow out to "$custom_ip"
                    echo "All outgoing to $custom_ip allowed"
                fi
                ;;
            5)
                break
                ;;
            *)
                echo "Invalid option"
                ;;
        esac
    done
fi

# Enable UFW
echo ""
echo "Enabling UFW..."
ufw --force enable

echo ""
echo "UFW Configuration Complete!"
echo ""
ufw status verbose