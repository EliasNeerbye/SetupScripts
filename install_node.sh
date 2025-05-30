#!/bin/bash

# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Source NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Install node lts
nvm install --lts

# Use default
nvm use default

# Reload shell
source ~/.bashrc

# Verify installation
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"