#!/bin/bash

set -e

echo "MongoDB Authentication Setup"

# Verify script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Start MongoDB if not running
if ! systemctl is-active --quiet mongod; then
    echo "Starting MongoDB service..."
    systemctl start mongod
    sleep 3
fi

# Wait for MongoDB to respond
echo "Waiting for MongoDB to be ready..."
timeout=30
while ! mongosh --eval "db.adminCommand('ping')" >/dev/null 2>&1; do
    sleep 1
    timeout=$((timeout - 1))
    if [ $timeout -eq 0 ]; then
        echo "MongoDB failed to start properly"
        exit 1
    fi
done

# Get machine IP for binding
MACHINE_IP=$(ip route get 1.1.1.1 | awk '{print $7; exit}')
echo "Detected machine IP: $MACHINE_IP"

# Check current configuration state
MONGOD_CONF="/etc/mongod.conf"
CONFIG_AUTH_ENABLED=false
if grep -q "authorization: enabled" "$MONGOD_CONF"; then
    CONFIG_AUTH_ENABLED=true
    echo "Configuration: Authentication is enabled"
else
    echo "Configuration: Authentication is disabled"
fi

# Check if MongoDB is currently running with authentication
RUNTIME_AUTH_ENABLED=false
if mongosh --eval "db.adminCommand('listUsers')" >/dev/null 2>&1; then
    echo "Runtime: MongoDB is running without authentication"
else
    echo "Runtime: MongoDB authentication appears to be enabled"
    RUNTIME_AUTH_ENABLED=true
fi

# Get credentials from user
read -r -p "Enter MongoDB admin username: " ADMIN_USERNAME
read -r -s -p "Enter MongoDB admin password: " ADMIN_PASSWORD
echo ""

# Handle user creation or validation based on current state
if [ "$RUNTIME_AUTH_ENABLED" = false ]; then
    echo "Creating MongoDB admin user..."
    
    # Check if any users exist
    USER_EXISTS=$(mongosh --quiet --eval "
    use admin
    db.getUsers().length > 0 ? 'true' : 'false'
    " 2>/dev/null || echo "false")
    
    if [ "$USER_EXISTS" = "true" ]; then
        echo "Users already exist in admin database"
        # Test credentials without auth (should work if auth is disabled)
        if mongosh --eval "use admin; db.auth('$ADMIN_USERNAME', '$ADMIN_PASSWORD')" >/dev/null 2>&1; then
            echo "User '$ADMIN_USERNAME' exists and credentials are valid"
        else
            echo "Cannot validate credentials - user may not exist or password is incorrect"
            exit 1
        fi
    else
        # Create new admin user
        if mongosh --eval "
        use admin
        try {
            db.createUser({
                user: '$ADMIN_USERNAME',
                pwd: '$ADMIN_PASSWORD',
                roles: ['root']
            })
            print('User created successfully')
        } catch (e) {
            if (e.code === 11000) {
                print('User already exists')
            } else {
                throw e
            }
        }
        "; then
            echo "Admin user created successfully"
        else
            echo "Failed to create admin user"
            exit 1
        fi
    fi
else
    # Test provided credentials with authentication
    if mongosh -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo "Authentication with existing credentials successful"
    else
        echo "Cannot authenticate with provided credentials"
        echo "You may need to use correct credentials or reset MongoDB authentication"
        exit 1
    fi
fi

# Create backup of mongod.conf
BACKUP_FILE="${MONGOD_CONF}.backup_$(date +%Y%m%d_%H%M%S)"
cp "$MONGOD_CONF" "$BACKUP_FILE"
echo "Backup created: $BACKUP_FILE"

# Update MongoDB configuration
echo "Updating MongoDB configuration..."
CONFIG_CHANGED=false

# Enable authentication in config
if [ "$CONFIG_AUTH_ENABLED" = false ]; then
    if grep -q "^#.*authorization:" "$MONGOD_CONF"; then
        sed -i 's/^#.*authorization:.*/  authorization: enabled/' "$MONGOD_CONF"
    elif grep -q "^security:" "$MONGOD_CONF"; then
        sed -i '/^security:/a\  authorization: enabled' "$MONGOD_CONF"
    else
        echo "security:" >> "$MONGOD_CONF"
        echo "  authorization: enabled" >> "$MONGOD_CONF"
    fi
    echo "Authorization enabled in mongod.conf"
    CONFIG_CHANGED=true
else
    echo "Authorization already enabled in mongod.conf"
fi

# Configure IP binding
CURRENT_BIND=$(grep "bindIp:" "$MONGOD_CONF" | cut -d: -f2 | tr -d ' ' || echo "127.0.0.1")
if [[ "$CURRENT_BIND" == *"$MACHINE_IP"* ]]; then
    echo "Machine IP $MACHINE_IP already in bindIp"
else
    if [[ "$CURRENT_BIND" == *"127.0.0.1"* ]]; then
        sed -i "s/bindIp: .*/bindIp: $MACHINE_IP,127.0.0.1/" "$MONGOD_CONF"
    else
        sed -i "s/bindIp: .*/bindIp: $MACHINE_IP,127.0.0.1/" "$MONGOD_CONF"
    fi
    echo "Updated bindIp to include $MACHINE_IP"
    CONFIG_CHANGED=true
fi

# Restart MongoDB if configuration changed
if [ "$CONFIG_CHANGED" = true ]; then
    echo "Restarting MongoDB service..."
    systemctl restart mongod
    sleep 5

    # Verify service started
    if systemctl is-active --quiet mongod; then
        echo "MongoDB restarted successfully"
    else
        echo "Failed to restart MongoDB. Restoring backup..."
        cp "$BACKUP_FILE" "$MONGOD_CONF"
        systemctl restart mongod
        exit 1
    fi
else
    echo "No configuration changes needed"
fi

# Test authentication with retry logic
echo "Testing authentication..."
MAX_RETRIES=10
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if mongosh -u "$ADMIN_USERNAME" -p "$ADMIN_PASSWORD" --authenticationDatabase admin --eval "db.adminCommand('ping')" >/dev/null 2>&1; then
        echo "Authentication test successful"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        echo "Authentication test failed, retrying... ($RETRY_COUNT/$MAX_RETRIES)"
        sleep 2
    fi
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
    echo "Authentication test failed after $MAX_RETRIES attempts"
    echo "MongoDB may need more time to start, or there's a configuration issue"
    exit 1
fi

echo ""
echo "Setup complete!"
echo "• Admin user: $ADMIN_USERNAME"
echo "• Authentication: enabled"
echo "• Bind IPs: 127.0.0.1, $MACHINE_IP"
echo ""
echo "Connect with: mongosh -u $ADMIN_USERNAME -p --authenticationDatabase admin"
echo "Or: mongosh mongodb://$ADMIN_USERNAME:$ADMIN_PASSWORD@localhost:27017/admin"