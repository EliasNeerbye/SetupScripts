#!/bin/bash

set -e

echo "API Deployment Script"

# Helper function for yes/no questions
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

# Get repository information
echo "Repository Setup:"
read -r -p "Enter repository name (default: use full URL): " REPO_NAME

if [[ $REPO_NAME == http* ]] || [[ $REPO_NAME == git@* ]]; then
    # Full URL provided
    REPO_URL="$REPO_NAME"
    REPO_DIR=$(basename "$REPO_URL" .git)
else
    # Just repo name provided, use default base URL
    if [ -z "$REPO_NAME" ]; then
        echo "Error: Repository name cannot be empty"
        exit 1
    fi
    REPO_URL="https://github.com/EliasNeerbye/$REPO_NAME"
    REPO_DIR="$REPO_NAME"
fi

echo "Repository URL: $REPO_URL"
echo "Local directory: $REPO_DIR"

# Clone repository
if [ -d "$REPO_DIR" ]; then
    if ask_yes_no "Directory '$REPO_DIR' already exists. Remove and re-clone?"; then
        rm -rf "$REPO_DIR"
    else
        echo "Using existing directory"
    fi
fi

if [ ! -d "$REPO_DIR" ]; then
    echo "Cloning repository..."
    git clone "$REPO_URL"
fi

cd "$REPO_DIR"

# Find directory with package.json
echo "Finding package.json..."
PACKAGE_DIR=$(find . -name "package.json" -type f | head -1 | xargs dirname)

if [ -z "$PACKAGE_DIR" ]; then
    echo "Error: No package.json found in repository"
    exit 1
fi

echo "Found package.json in: $PACKAGE_DIR"
cd "$PACKAGE_DIR"

# Install dependencies
echo "Installing dependencies..."
npm install

# Handle .env file
if [ -f ".env.example" ]; then
    echo ""
    echo "Found .env.example file"
    
    if [ -f ".env" ]; then
        if ask_yes_no ".env already exists. Overwrite?"; then
            rm .env
        else
            echo "Keeping existing .env file"
        fi
    fi
    
    if [ ! -f ".env" ]; then
        echo "Creating .env from .env.example..."
        cp .env.example .env
        
        echo ""
        echo "Environment variables to configure:"
        echo "=================================="
        
        # Read .env.example and prompt for changes
        while IFS= read -r line; do
            # Skip empty lines and comments
            if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Extract key and value
            if [[ "$line" =~ ^([^=]+)=(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                value="${BASH_REMATCH[2]}"
                
                echo ""
                echo "Current: $key=$value"
                read -r -p "New value (or press Enter to keep current): " new_value
                
                if [ -n "$new_value" ]; then
                    # Escape special characters for sed
                    escaped_key=$(echo "$key" | sed 's/[[\.*^$()+?{|]/\\&/g')
                    escaped_value=$(echo "$new_value" | sed 's/[[\.*^$()+?{|]/\\&/g')
                    sed -i "s/^${escaped_key}=.*/${escaped_key}=${escaped_value}/" .env
                    echo "Updated: $key=$new_value"
                fi
            fi
        done < .env.example
        
        echo ""
        echo ".env file created and configured"
    fi
else
    echo "No .env.example found, skipping environment setup"
fi

# Install PM2 if not present
if ! command -v pm2 &> /dev/null; then
    echo ""
    echo "PM2 not found. Installing globally..."
    npm install -g pm2
fi

# Find main application file
MAIN_FILE=""
for file in "server.js" "app.js" "index.js"; do
    if [ -f "$file" ]; then
        MAIN_FILE="$file"
        break
    fi
done

if [ -z "$MAIN_FILE" ]; then
    echo ""
    echo "Could not find server.js, app.js, or index.js"
    read -r -p "Enter the main application file: " MAIN_FILE
    
    if [ ! -f "$MAIN_FILE" ]; then
        echo "Error: File '$MAIN_FILE' not found"
        exit 1
    fi
fi

echo ""
echo "Starting application with PM2..."
echo "Main file: $MAIN_FILE"

# Get app name for PM2
APP_NAME=$(basename "$(pwd)")
read -r -p "Enter PM2 app name (default: $APP_NAME): " PM2_NAME
PM2_NAME=${PM2_NAME:-$APP_NAME}

# Stop existing PM2 process if it exists
if pm2 list | grep -q "$PM2_NAME"; then
    echo "Stopping existing PM2 process: $PM2_NAME"
    pm2 stop "$PM2_NAME"
    pm2 delete "$PM2_NAME"
fi

# Start application with PM2
pm2 start "$MAIN_FILE" --name "$PM2_NAME"

# Save PM2 configuration
pm2 save

# Setup PM2 startup (if not already done)
if ask_yes_no "Configure PM2 to start on system boot?"; then
    pm2 startup
    echo ""
    echo "Note: You may need to run the command shown above to complete startup configuration"
fi

echo ""
echo "Deployment complete!"
echo "==================="
echo "• Repository: $REPO_URL"
echo "• Directory: $(pwd)"
echo "• Main file: $MAIN_FILE"
echo "• PM2 app name: $PM2_NAME"
echo ""
echo "Useful commands:"
echo "• View logs: pm2 logs $PM2_NAME"
echo "• Restart app: pm2 restart $PM2_NAME"
echo "• Stop app: pm2 stop $PM2_NAME"
echo "• PM2 status: pm2 status"
