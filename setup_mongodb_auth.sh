#!/bin/bash

set -e

echo "MongoDB Authentication Setup"

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Check if MongoDB is running
if ! systemctl is-active --quiet mongod; then
    echo "Starting MongoDB service..."
    systemctl start mongod
fi

# Get machine's IP address (excluding localhost)
MACHINE_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo "Detected machine IP: $MACHINE_IP"

# Get admin user credentials
read -r -p "Enter MongoDB admin username: " ADMIN_USERNAME
read -r -s -p "Enter MongoDB admin password: " ADMIN_PASSWORD
echo ""

# Create admin user
echo "Creating MongoDB admin user..."
mongosh --eval "
use admin
db.createUser({
  user: '$ADMIN_USERNAME',
  pwd: '$ADMIN_PASSWORD',
  roles: ['root']
})
"

if [ $? -eq 0 ]; then
    echo "Admin user '$ADMIN_USERNAME' created successfully"
else
    echo "Failed to create admin user"
    exit 1
fi

# Backup mongod.conf
MONGOD_CONF="/etc/mongod.conf"
BACKUP_FILE="${MONGOD_CONF}.backup_$(date +%Y%m%d_%H%M%S)"
cp "$MONGOD_CONF" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Update mongod.conf for authentication and IP binding
echo "Updating MongoDB configuration..."

# Check if authorization is already enabled
if grep -q "authorization: enabled" "$MONGOD_CONF"; then
    echo "Authorization already enabled in mongod.conf"
else
    # Enable authorization by uncommenting or adding the security section
    if grep -q "^#.*authorization:" "$MONGOD_CONF"; then
        # Uncomment existing line
        sed -i 's/^#.*authorization:.*/  authorization: enabled/' "$MONGOD_CONF"
    elif grep -q "^security:" "$MONGOD_CONF"; then
        # Add authorization under existing security section
        sed -i '/^security:/a\  authorization: enabled' "$MONGOD_CONF"
    else
        # Add entire security section
        echo "security:" >> "$MONGOD_CONF"
        echo "  authorization: enabled" >> "$MONGOD_CONF"
    fi
    echo "Authorization enabled in mongod.conf"
fi

# Update bindIp to include machine IP
CURRENT_BIND=$(grep "bindIp:" "$MONGOD_CONF" | cut -d: -f2 | tr -d ' ')
if [[ "$CURRENT_BIND" == *"$MACHINE_IP"* ]]; then
    echo "Machine IP $MACHINE_IP already in bindIp"
else
    if [[ "$CURRENT_BIND" == *"127.0.0.1"* ]]; then
        # Add machine IP to existing bindIp
        sed -i "s/bindIp: .*/bindIp: $MACHINE_IP,127.0.0.1/" "$MONGOD_CONF"
    else
        # Replace bindIp entirely
        sed -i "s/bindIp: .*/bindIp: $MACHINE_IP,127.0.0.1/" "$MONGOD_CONF"
    fi
    echo "Updated bindIp to include $MACHINE_IP"
fi

echo "MongoDB configuration updated"

# Restart MongoDB service
echo "Restarting MongoDB service..."
systemctl restart mongod

# Verify service is running
if systemctl is-active --quiet mongod; then
    echo "MongoDB restarted successfully"
else
    echo "Failed to restart MongoDB. Restoring backup..."
    cp "$BACKUP_FILE" "$MONGOD_CONF"
    systemctl restart mongod
    exit 1
fi

# Test authentication
echo "Testing authentication..."
if mongosh -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ismaster')" > /dev/null 2>&1; then
    echo "Authentication test successful"
else
    echo "Authentication test failed"
    exit 1
fi

echo ""
echo "Setup complete!"
echo "• Admin user: $ADMIN_USERNAME"
echo "• Authentication: enabled"
echo "• Bind IPs: 127.0.0.1, $MACHINE_IP"
echo ""
echo "Connect with: mongosh -u $ADMIN_USERNAME -p --authenticationDatabase admin"
