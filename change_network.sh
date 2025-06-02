#!/bin/bash

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root. Please use 'sudo ./change_network.sh'" >&2
  exit 1
fi

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
    read -r -p "Could not automatically find a Netplan config file. Please enter the full path to your Netplan YAML file (e.g., /etc/netplan/custom.yaml): " NETPLAN_CONFIG_FILE
    if [ ! -f "$NETPLAN_CONFIG_FILE" ]; then
        echo "Error: Netplan configuration file '$NETPLAN_CONFIG_FILE' not found. Exiting."
        exit 1
    fi
fi

# Get current hostname
CURRENT_HOSTNAME=$(hostname)
echo "-------------------------------------"
echo "Hostname Configuration"
echo "-------------------------------------"
read -r -p "Current hostname is '$CURRENT_HOSTNAME'. Enter new hostname (or press Enter to skip): " NEW_HOSTNAME

CURRENT_IP_LINE=$(grep -E "^\s*-\s*([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}" "$NETPLAN_CONFIG_FILE" | head -n 1)
CURRENT_IP_WITH_MASK=$(echo "$CURRENT_IP_LINE" | sed -e 's/^[[:space:]]*-\s*//') # Remove leading spaces and hyphen
CURRENT_IP_BASE=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f1 | cut -d'.' -f1-3)
CURRENT_LAST_OCTET=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f1 | cut -d'.' -f4)
CURRENT_SUBNET_MASK=$(echo "$CURRENT_IP_WITH_MASK" | cut -d'/' -f2)

if [ -z "$CURRENT_IP_BASE" ] || [ -z "$CURRENT_LAST_OCTET" ] || [ -z "$CURRENT_SUBNET_MASK" ]; then
    echo ""
    echo "Warning: Could not reliably determine the current IP address structure from '$NETPLAN_CONFIG_FILE'."
    echo "The Netplan section provided was:"
    echo "\"\"\""
    echo "network:"
    echo "  ethernets:"
    echo "    ens33:"
    echo "      addresses:"
    echo "      - 10.12.90.84/24"
    echo "      gateway4: 10.12.90.1"
    echo "      nameservers:"
    echo "        addresses:"
    echo "        - 10.10.1.30"
    echo "        - 8.8.8.8"
    echo "        - 9.9.9.9"
    echo "        search: []"
    echo "  version: 2"
    echo "\"\"\""
    echo "Attempting to use default values from your request (10.12.90.x/24)."
    CURRENT_IP_BASE="10.12.90"
    CURRENT_LAST_OCTET="84"
    CURRENT_SUBNET_MASK="24"
fi

echo ""
echo "-------------------------------------"
echo "Network Configuration (Netplan)"
echo "-------------------------------------"
echo "Current IP address is approximately: $CURRENT_IP_BASE.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK"
read -r -p "Enter new last octet for the IP address (e.g., for 10.12.90.X, enter X. Press Enter to skip): " NEW_LAST_OCTET

# --- Variable to track if changes were made ---
CHANGES_MADE=false
NETPLAN_CHANGED=false
HOSTNAME_CHANGED=false

# --- Update Hostname ---
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
    HOSTNAME_CHANGED=true
else
    echo "Hostname will not be changed."
fi

# --- Update Netplan IP Address ---
if [ -n "$NEW_LAST_OCTET" ]; then
    if ! [[ "$NEW_LAST_OCTET" =~ ^[0-9]+$ ]] || [ "$NEW_LAST_OCTET" -lt 0 ] || [ "$NEW_LAST_OCTET" -gt 255 ]; then
        echo "Error: Invalid last octet '$NEW_LAST_OCTET'. It must be a number between 0 and 255."
        echo "IP address will not be changed."
    elif [ "$NEW_LAST_OCTET" == "$CURRENT_LAST_OCTET" ]; then
        echo "New last octet is the same as the current one. IP address will not be changed."
    else
        NEW_IP_ADDRESS="$CURRENT_IP_BASE.$NEW_LAST_OCTET/$CURRENT_SUBNET_MASK"
        OLD_IP_ADDRESS_PATTERN="$CURRENT_IP_BASE\\.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK"

        echo "Updating IP address in '$NETPLAN_CONFIG_FILE' from '$OLD_IP_ADDRESS_PATTERN' to '$NEW_IP_ADDRESS'..."

        cp "$NETPLAN_CONFIG_FILE" "$NETPLAN_CONFIG_FILE.bak_$(date +%Y%m%d_%H%M%S)"
        echo "Backup of Netplan config created at $NETPLAN_CONFIG_FILE.bak_$(date +%Y%m%d_%H%M%S)"

        if grep -q "ens33:" "$NETPLAN_CONFIG_FILE" && grep -q "$CURRENT_IP_BASE.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK" "$NETPLAN_CONFIG_FILE"; then
            sed -i "s|$CURRENT_IP_BASE\.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK|$NEW_IP_ADDRESS|g" "$NETPLAN_CONFIG_FILE"
            echo "Netplan IP address updated in the file."
            CHANGES_MADE=true
            NETPLAN_CHANGED=true
        else
            echo "Error: Could not find the IP address '$CURRENT_IP_BASE.$CURRENT_LAST_OCTET/$CURRENT_SUBNET_MASK' under an 'ens33' interface in '$NETPLAN_CONFIG_FILE'."
            echo "Please check the file content and the script's IP detection logic."
            echo "Netplan configuration not changed."
        fi
    fi
else
    echo "Last octet of IP address will not be changed."
fi

# --- Apply Changes ---
echo ""
echo "-------------------------------------"
echo "Applying Changes"
echo "-------------------------------------"
if [ "$CHANGES_MADE" = true ]; then
    if [ "$NETPLAN_CHANGED" = true ]; then
        echo "Applying Netplan configuration..."
        reboot now
    fi
else
    echo "No changes were made."
fi

exit 0
