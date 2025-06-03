#!/bin/bash

set -e

echo "Setting up nginx reverse proxy..."

# Check root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (use sudo)"
   exit 1
fi

# Configure non-interactive mode
export DEBIAN_FRONTEND=noninteractive
mkdir -p /etc/needrestart/conf.d/
cat > /etc/needrestart/conf.d/50-no-interactive.conf << 'EOF'
$nrconf{restart} = 'a';
$nrconf{ui} = 0;
EOF

# Install nginx
echo "Installing nginx..."
apt update
apt install -y nginx

# Create reverse proxy configuration
echo "Creating reverse proxy configuration..."
cat > /etc/nginx/sites-available/userapi << 'EOF'
server {
    listen 80;
    server_name userapi.harpy.ikt-fag.no 10.12.90.100;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Remove default configuration
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "Default configuration removed"
fi

# Enable new configuration
if [ ! -L /etc/nginx/sites-enabled/userapi ]; then
    ln -s /etc/nginx/sites-available/userapi /etc/nginx/sites-enabled/userapi
    echo "Configuration enabled"
fi

# Test configuration
if nginx -t; then
    echo "Nginx configuration syntax is valid"
else
    echo "Nginx configuration syntax error!"
    exit 1
fi

# Enable and start service
systemctl enable nginx

if systemctl is-active --quiet nginx; then
    echo "Reloading nginx configuration..."
    systemctl reload nginx
else
    echo "Starting nginx..."
    systemctl start nginx
fi

# Verify service
if systemctl is-active --quiet nginx; then
    echo "Nginx is running successfully!"
else
    echo "Nginx failed to start!"
    systemctl status nginx
    exit 1
fi

echo ""
echo "Setup complete!"
echo "• Reverse proxy configured for localhost:3000"
echo "• Accepts: userapi.harpy.ikt-fag.no and 10.12.90.100"
echo "• Test with: curl http://userapi.harpy.ikt-fag.no"