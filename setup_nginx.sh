#!/bin/bash

# nginx Reverse Proxy Setup Script
# Sets up nginx to proxy API requests to localhost:3000

set -e  # Exit on any error

echo "🚀 Starting nginx reverse proxy setup..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)"
   exit 1
fi

# Suppress interactive prompts and restart notifications
export DEBIAN_FRONTEND=noninteractive

# Configure needrestart to not show interactive UI
echo "🔧 Configuring system to avoid restart prompts..."
mkdir -p /etc/needrestart/conf.d/
cat > /etc/needrestart/conf.d/50-no-interactive.conf << 'EOF'
# Disable interactive mode for automated scripts
$nrconf{restart} = 'a';
$nrconf{ui} = 0;
EOF

# Update package list and install nginx
echo "📦 Installing nginx..."
apt update
apt install -y nginx

# Create the reverse proxy configuration
echo "⚙️  Creating reverse proxy configuration..."
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

echo "✅ Configuration file created at /etc/nginx/sites-available/userapi"

# Remove default nginx configuration
echo "🗑️  Removing default nginx configuration..."
if [ -L /etc/nginx/sites-enabled/default ]; then
    rm /etc/nginx/sites-enabled/default
    echo "✅ Default configuration removed"
else
    echo "ℹ️  Default configuration not found (already removed)"
fi

# Link the new configuration
echo "🔗 Enabling new configuration..."
if [ ! -L /etc/nginx/sites-enabled/userapi ]; then
    ln -s /etc/nginx/sites-available/userapi /etc/nginx/sites-enabled/userapi
    echo "✅ Configuration linked successfully"
else
    echo "ℹ️  Configuration already linked"
fi

# Test nginx configuration syntax
echo "🧪 Testing nginx configuration syntax..."
if nginx -t; then
    echo "✅ Nginx configuration syntax is valid"
else
    echo "❌ Nginx configuration syntax error!"
    echo "Check the configuration and try again."
    exit 1
fi

# Enable nginx service
echo "🔧 Enabling nginx service..."
systemctl enable nginx

# Start/restart nginx
echo "🚀 Starting nginx service..."
if systemctl is-active --quiet nginx; then
    echo "🔄 Nginx is running, reloading configuration..."
    systemctl reload nginx
else
    echo "▶️  Starting nginx..."
    systemctl start nginx
fi

# Check nginx status
echo "📊 Checking nginx status..."
if systemctl is-active --quiet nginx; then
    echo "✅ Nginx is running successfully!"
else
    echo "❌ Nginx failed to start!"
    systemctl status nginx
    exit 1
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Summary:"
echo "   • Nginx installed and configured"
echo "   • Reverse proxy setup for localhost:3000"
echo "   • Server accepts: userapi.harpy.ikt-fag.no and 10.12.90.100"
echo "   • Default configuration removed"
echo "   • Service enabled and started"
echo ""
echo "🔧 Next steps:"
echo "   • Make sure your API is running on localhost:3000"
echo "   • Test the setup: curl http://userapi.harpy.ikt-fag.no"
echo "   • Check logs: tail -f /var/log/nginx/userapi_*.log"
echo ""
echo "📁 Configuration files:"
echo "   • Main config: /etc/nginx/sites-available/userapi"
echo "   • Symlink: /etc/nginx/sites-enabled/userapi"
