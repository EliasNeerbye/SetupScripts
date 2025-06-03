#!/bin/bash

set -e

echo "SSH Match Blocks Setup"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Helper functions
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

SSHD_CONFIG="/etc/ssh/sshd_config"

# Get original user
if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER="$SUDO_USER"
else
    ORIGINAL_USER="$USER"
fi

echo "Current user: $ORIGINAL_USER"

# Create backup
BACKUP_FILE="${SSHD_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)"
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Remove existing match blocks if present
if grep -q "^Match User\|^Match Address" "$SSHD_CONFIG"; then
    echo "Found existing Match blocks"
    if ask_yes_no "Remove existing Match blocks and continue?"; then
        sed -i '/^Match User\|^Match Address/,/^$/d' "$SSHD_CONFIG"
        sed -i '/^[[:space:]]*PasswordAuthentication\|^[[:space:]]*PubkeyAuthentication/d' "$SSHD_CONFIG"
    else
        echo "Aborted."
        exit 1
    fi
fi

# Get trusted IP for password authentication
trusted_ip=$(get_ip_input "Enter trusted IP address for password authentication")

# Add match blocks
cat >> "$SSHD_CONFIG" << EOF

# Custom Match Blocks
# User: $ORIGINAL_USER - Key-only authentication
Match User $ORIGINAL_USER
    PasswordAuthentication no
    PubkeyAuthentication yes

# User: eksaminator - Both password and key authentication
Match User eksaminator
    PasswordAuthentication yes
    PubkeyAuthentication yes

# Trusted IP: $trusted_ip - Password authentication allowed
Match Address $trusted_ip
    PasswordAuthentication yes
EOF

echo "Match blocks added to SSH config"

# Test configuration
if sshd -t; then
    echo "SSH configuration syntax is valid"
else
    echo "SSH configuration syntax error! Restoring backup..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    echo "Configuration restored. No changes applied."
    exit 1
fi

# Summary
echo ""
echo "Configuration Summary:"
echo "• User '$ORIGINAL_USER': Key-only authentication"
echo "• User 'eksaminator': Password + key authentication"
echo "• IP '$trusted_ip': Password authentication allowed"

# Restart SSH service
if ask_yes_no "Restart SSH service now?"; then
    systemctl restart sshd
    echo "SSH service restarted"
else
    echo "Remember to restart SSH: sudo systemctl restart sshd"
fi

echo "Setup complete! Test SSH access before closing this session."