#!/bin/bash

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use 'sudo ./change_network.sh'" >&2
  exit 1
fi

# Find Netplan configuration file
NETPLAN_CONFIG_FILE=""
POSSIBLE_FILES=("/etc/netplan/00-installer-config.yaml" "/etc/netplan/50-cloud-init.yaml")

for file in "${POSSIBLE_FILES[@]}"; do
    if [ -f "$file" ]; then
        NETPLAN_CONFIG_FILE="$file"
        echo "Found Netplan configuration file: $NETPLAN_CONFIG_FILE"
        break
    fi
done

if [ -z "$NETPLAN_CONFIG_FILE" ]; then
    ls -la /etc/netplan/
    read -r -p "Enter full path to your Netplan YAML file: " NETPLAN_CONFIG_FILE
    if [ ! -f "$NETPLAN_CONFIG_FILE" ]; then
        echo "Error: Netplan configuration file '$NETPLAN_CONFIG_FILE' not found."
        exit 1
    fi
fi

# Get hostname input
CURRENT_HOSTNAME=$(hostname)
echo "Current hostname: '$CURRENT_HOSTNAME'"
read -r -p "Enter new hostname (or press Enter to skip): " NEW_HOSTNAME

# Extract current IP configuration
CURRENT_IP_LINE=$(grep -E "^\s*-\s*([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}" "$NETPLAN_CONFIG_FILE" | head -n 1)
CURRENT_IP_WITH_MASK=$(echo "$CURRENT_IP_LINE" | sed -e 's/^[[:space:]]*-\s*//')
CURRENT_IP_BASE=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f1 | cut -d'.' -f1-3)
CURRENT_LAST_OCTET=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f1 | cut -d'.' -f4)
CURRENT_SUBNET_MASK=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f2)

# Use defaults if extraction fails
if [ -z "$CURRENT_IP_BASE" ] || [ -z "$CURRENT_LAST_OCTET" ] || [ -z "$CURRENT_SUBNET_MASK" ]; then
    echo "Warning: Could not determine current IP. Using defaults (10.12.90.x/24)."
    CURRENT_IP_BASE="10.12.90"
    CURRENT_LAST_OCTET="84"
    CURRENT_SUBNET_MASK="24"
fi

# Get IP input
echo "Current IP: $CURRENT_IP_BASE.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK"
read -r -p "Enter new last octet (or press Enter to skip): " NEW_LAST_OCTET

CHANGES_MADE=false
NETPLAN_CHANGED=false

# Update hostname
if [ -n "$NEW_HOSTNAME" ] && [ "$NEW_HOSTNAME" != "$CURRENT_HOSTNAME" ]; then
    echo "Updating hostname to '$NEW_HOSTNAME'..."
    hostnamectl set-hostname "$NEW_HOSTNAME"

    if grep -q "127.0.1.1.*$CURRENT_HOSTNAME" /etc/hosts; then
        sed -i "s/127.0.1.1.*$CURRENT_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/g" /etc/hosts
    elif ! grep -q "127.0.1.1.*$NEW_HOSTNAME" /etc/hosts; then
        echo "127.0.1.1    $NEW_HOSTNAME" >> /etc/hosts
    fi
    echo "Hostname updated."
    CHANGES_MADE=true
fi

# Update IP address
if [ -n "$NEW_LAST_OCTET" ]; then
    if ! [[ "$NEW_LAST_OCTET" =~ ^[0-9]+$ ]] || [ "$NEW_LAST_OCTET" -lt 0 ] || [ "$NEW_LAST_OCTET" -gt 255 ]; then
        echo "Error: Invalid last octet. Must be 0-255."
    elif [ "$NEW_LAST_OCTET" == "$CURRENT_LAST_OCTET" ]; then
        echo "New octet same as current. No change needed."
    else
        NEW_IP_ADDRESS="$CURRENT_IP_BASE.$NEW_LAST_OCTET/$CURRENT_SUBNET_MASK"
        
        echo "Updating IP to $NEW_IP_ADDRESS..."
        cp "$NETPLAN_CONFIG_FILE" "$NETPLAN_CONFIG_FILE.bak_$(date +%Y%m%d_%H%M%S)"
        
        if grep -q "ens33:" "$NETPLAN_CONFIG_FILE" && grep -q "$CURRENT_IP_BASE.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK" "$NETPLAN_CONFIG_FILE"; then
            sed -i "s|$CURRENT_IP_BASE\.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK|$NEW_IP_ADDRESS|g" "$NETPLAN_CONFIG_FILE"
            echo "IP address updated."
            CHANGES_MADE=true
            NETPLAN_CHANGED=true
        else
            echo "Error: Could not find current IP in Netplan file."
        fi
    fi
fi

# Apply changes
if [ "$CHANGES_MADE" = true ]; then
    if [ "$NETPLAN_CHANGED" = true ]; then
        echo "Applying Netplan configuration..."
        reboot now
    fi
else
    echo "No changes were made."
fi

exit 0