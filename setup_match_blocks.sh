#!/bin/bash

# SSH Match Blocks Setup Script
# Configures SSH authentication rules for different users and IP addresses

set -e  # Exit on any error

echo "🔐 SSH Match Blocks Setup Script"
echo "================================="

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

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

SSHD_CONFIG="/etc/ssh/sshd_config"

# Get the original user (in case script is run with sudo)
if [ -n "$SUDO_USER" ]; then
    ORIGINAL_USER="$SUDO_USER"
else
    ORIGINAL_USER="$USER"
fi

echo ""
echo "🔍 Current user detected: $ORIGINAL_USER"

# Create backup of SSH config
BACKUP_FILE="${SSHD_CONFIG}.backup_$(date +%Y%m%d_%H%M%S)"
echo "💾 Creating backup of SSH config..."
cp "$SSHD_CONFIG" "$BACKUP_FILE"
echo "✅ Backup created: $BACKUP_FILE"

# Check if match blocks already exist
if grep -q "^Match User\|^Match Address" "$SSHD_CONFIG"; then
    echo ""
    echo "⚠️  Existing Match blocks found in SSH config!"
    if ask_yes_no "Do you want to remove existing Match blocks and continue?"; then
        echo "🗑️  Removing existing Match blocks..."
        # Remove existing match blocks and their settings
        sed -i '/^Match User\|^Match Address/,/^$/d' "$SSHD_CONFIG"
        # Also remove any orphaned authentication settings at the end
        sed -i '/^[[:space:]]*PasswordAuthentication\|^[[:space:]]*PubkeyAuthentication/d' "$SSHD_CONFIG"
    else
        echo "❌ Aborted. No changes made."
        exit 1
    fi
fi

echo ""
echo "📋 Configuring Match Blocks"
echo "============================"

# Get IP address for the third match block
trusted_ip=$(get_ip_input "Enter trusted IP address for password authentication")

echo ""
echo "📝 Adding Match blocks to SSH configuration..."

# Add match blocks to the end of the SSH config
cat >> "$SSHD_CONFIG" << EOF

# Custom Match Blocks - Added by setup_ssh_match_blocks.sh
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

echo "✅ Match blocks added to $SSHD_CONFIG"

# Validate SSH configuration
echo ""
echo "🧪 Testing SSH configuration syntax..."
if sshd -t; then
    echo "✅ SSH configuration syntax is valid"
else
    echo "❌ SSH configuration syntax error!"
    echo "🔄 Restoring backup..."
    cp "$BACKUP_FILE" "$SSHD_CONFIG"
    echo "❌ Configuration restored from backup. No changes applied."
    exit 1
fi

# Show what was configured
echo ""
echo "📋 Configuration Summary:"
echo "========================="
echo "✅ User '$ORIGINAL_USER':"
echo "   • Password authentication: DISABLED"
echo "   • Public key authentication: ENABLED"
echo ""
echo "✅ User 'eksaminator':"
echo "   • Password authentication: ENABLED"
echo "   • Public key authentication: ENABLED"
echo ""
echo "✅ IP address '$trusted_ip':"
echo "   • Password authentication: ENABLED"
echo ""

# Ask about restarting SSH
echo "⚠️  SSH service needs to be restarted to apply changes."
if ask_yes_no "Restart SSH service now?"; then
    echo "🔄 Restarting SSH service..."
    systemctl restart sshd
    echo "✅ SSH service restarted successfully"
    
    echo ""
    echo "🎉 SSH Match blocks configured successfully!"
else
    echo ""
    echo "⚠️  Remember to restart SSH service manually:"
    echo "   sudo systemctl restart sshd"
fi

echo ""
echo "💡 Important Notes:"
echo "==================="
echo "• Make sure user '$ORIGINAL_USER' has SSH keys configured"
echo "• Test SSH access before closing this session"
echo "• Backup file saved at: $BACKUP_FILE"
echo ""
echo "🔧 Useful commands:"
echo "   • Test SSH config: sudo sshd -t"
echo "   • View SSH config: sudo cat /etc/ssh/sshd_config"
echo "   • Restart SSH: sudo systemctl restart sshd"
echo "   • SSH service status: sudo systemctl status sshd"
echo ""
echo "📁 Configuration file: $SSHD_CONFIG"
