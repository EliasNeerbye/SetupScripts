#!/bin/bash

set -e

echo "Setting up custom terminal greeting..."

# Determine target user and home directory
if [ -n "$SUDO_USER" ]; then
    USER_HOME=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    TARGET_USER="$SUDO_USER"
else
    USER_HOME="$HOME"
    TARGET_USER="$USER"
fi

echo "Target user: $TARGET_USER"

# Create .hushlogin to suppress system login messages
HUSHLOGIN_FILE="$USER_HOME/.hushlogin"
if [ ! -f "$HUSHLOGIN_FILE" ]; then
    touch "$HUSHLOGIN_FILE"
    echo "Created .hushlogin"
fi

# Set correct ownership if running with sudo
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$HUSHLOGIN_FILE"
fi

# Add custom greeting to .bashrc
BASHRC_FILE="$USER_HOME/.bashrc"
if [ ! -f "$BASHRC_FILE" ]; then
    echo "Error: .bashrc not found at $BASHRC_FILE"
    exit 1
fi

# Check if greeting already exists
if grep -q "Hello \$USER!" "$BASHRC_FILE"; then
    echo "Custom greeting already exists in .bashrc"
else
    # Add ASCII art greeting
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

    echo "Custom greeting added to .bashrc"
fi

# Set correct ownership if running with sudo
if [ -n "$SUDO_USER" ]; then
    chown "$SUDO_USER:$SUDO_USER" "$BASHRC_FILE"
fi

echo "Setup complete! Run 'source ~/.bashrc' to test."