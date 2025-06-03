#!/bin/bash

# Custom Greeting Setup Script
# Creates .hushlogin and adds ASCII art greeting to .bashrc

set -e  # Exit on any error

echo "🎨 Setting up custom terminal greeting..."

# Get the user's home directory
if [ -n "$SUDO_USER" ]; then
    # If running with sudo, get the original user's home
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    TARGET_USER="$SUDO_USER"
else
    # If running as regular user
    USER_HOME="$HOME"
    TARGET_USER="$USER"
fi

echo "🏠 Target user home directory: $USER_HOME"
echo "👤 Target user: $TARGET_USER"

# Create .hushlogin file to suppress login messages
HUSHLOGIN_FILE="$USER_HOME/.hushlogin"
echo "🤫 Creating .hushlogin file to suppress system login messages..."

if [ ! -f "$HUSHLOGIN_FILE" ]; then
    touch "$HUSHLOGIN_FILE"
    echo "✅ Created $HUSHLOGIN_FILE"
else
    echo "ℹ️  .hushlogin already exists"
fi

# Set correct ownership if running as root/sudo
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$HUSHLOGIN_FILE"
fi

# Add custom greeting to .bashrc
BASHRC_FILE="$USER_HOME/.bashrc"
echo "📝 Adding custom greeting to .bashrc..."

# Check if .bashrc exists
if [ ! -f "$BASHRC_FILE" ]; then
    echo "❌ .bashrc not found at $BASHRC_FILE"
    exit 1
fi

# Check if our greeting is already added
if grep -q "Hello \$USER!" "$BASHRC_FILE"; then
    echo "ℹ️  Custom greeting already exists in .bashrc"
else
    # Add the greeting to the end of .bashrc
    cat >> "$BASHRC_FILE" << 'EOF'

# Custom ASCII art greeting
echo "      .-\"\"\"\"-."
echo "    .'        '."
echo "   /            \\"
echo "  |              |"
echo "  |,  .-.  .-.  ,|"
echo "  | )(_o/  \\o_)( |"
echo "  |/     /\\     \\|"
echo "  (_     ^^     _)"
echo "   \\__|IIIIII|__/"
echo "    | \\IIIIII/ |"
echo "    \\          /"
echo "     \`--------\`"
echo "Hello $USER!"
EOF

    echo "✅ Custom greeting added to .bashrc"
fi

# Set correct ownership if running as root/sudo
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$BASHRC_FILE"
fi

echo ""
echo "🎉 Setup complete!"
echo ""
echo "📋 Summary:"
echo "   • .hushlogin created to suppress system login messages"
echo "   • Custom ASCII art greeting added to .bashrc"
echo "   • Greeting will appear on next login/terminal session"
echo ""
echo "🔧 To test the greeting:"
echo "   source ~/.bashrc"
echo ""
echo "📁 Files modified:"
echo "   • $HUSHLOGIN_FILE"
echo "   • $BASHRC_FILE"
