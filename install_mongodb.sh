#!/bin/bash

# Import MongoDB public GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
   --dearmor

# Create list file
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list

# Update package list
sudo apt-get update

# Install MongoDB (with non-interactive flag to skip restart services dialog)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mongodb-org

# Start and enable MongoDB service
sudo systemctl start mongod
sudo systemctl enable mongod

# Verify installation
echo "MongoDB version: $(mongod --version | head -1)"
echo "MongoDB service status: $(systemctl is-active mongod)"