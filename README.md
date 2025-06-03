# Server Setup Scripts

A collection of bash scripts for quickly setting up and configuring Ubuntu servers with common development tools and services.

## Overview

These scripts automate the installation and configuration of essential server components including Node.js, MongoDB, Nginx, and network settings. Perfect for rapid deployment and consistent server configurations.

## Scripts

### 🌐 Network Configuration

**`change_network.sh`**
- Updates system hostname and static IP address
- Automatically detects and modifies Netplan configuration
- **Hardcoded for 10.12.90.X network** - modify for your network
- Creates backup of original configuration
- Requires root privileges

```bash
sudo ./change_network.sh
```

### 🚀 Development Environment

**`install_node.sh`**
- Installs Node.js via NVM (Node Version Manager)
- Installs the latest LTS version
- Sets up proper shell environment

```bash
./install_node.sh
source ~/.bashrc  # Required after installation
```

**`install_mongodb.sh`**
- Installs MongoDB Community Server 8.0
- Configures and starts MongoDB service
- Enables automatic startup on boot
- Adds MongoDB shell (mongosh) to PATH

```bash
./install_mongodb.sh
source ~/.bashrc  # For mongosh access
```

### 🔀 Reverse Proxy

**`setup_nginx.sh`**
- Installs and configures Nginx as a reverse proxy
- **Hardcoded configuration** for `userapi.harpy.ikt-fag.no` and `10.12.90.100`
- Proxies requests to `localhost:3000`
- Removes default Nginx configuration
- Requires root privileges

```bash
sudo ./setup_nginx.sh
```

### 🎨 Terminal Customization

**`setup_custom_greeting.sh`**
- Creates `.hushlogin` to suppress system login messages
- Adds custom ASCII art greeting to `.bashrc`
- Safe to run multiple times (won't create duplicates)

```bash
./setup_custom_greeting.sh
```

## Prerequisites

- Ubuntu Server (tested on Ubuntu 22.04 LTS)
- Internet connection for package downloads
- Root/sudo access for system-level scripts

## Quick Start

1. **Clone or download** these scripts to your server
2. **Make scripts executable:**
   ```bash
   chmod +x *.sh
   ```
3. **Run scripts as needed** (see individual script requirements above)

## Important Notes

⚠️ **Hardcoded Values**: Some scripts contain hardcoded network configurations and domain names. Review and modify these before use:

- `change_network.sh`: Network range `10.12.90.X`
- `setup_nginx.sh`: Domain `userapi.harpy.ikt-fag.no` and IP `10.12.90.100`

🔄 **Shell Reload**: After running Node.js or MongoDB installation scripts, reload your shell:
```bash
source ~/.bashrc
```

🛡️ **Root Access**: Network and Nginx scripts require root privileges for system configuration.

## Troubleshooting

- **Permission denied**: Ensure scripts are executable (`chmod +x script.sh`)
- **Network script fails**: Verify Netplan configuration file exists
- **Nginx fails to start**: Check configuration syntax with `nginx -t`
- **Node/MongoDB not found**: Run `source ~/.bashrc` to reload environment

## File Structure

```
.
├── README.md                    # This file
├── change_network.sh           # Network configuration
├── install_node.sh             # Node.js installation
├── install_mongodb.sh          # MongoDB installation
├── setup_nginx.sh              # Nginx reverse proxy
└── setup_custom_greeting.sh    # Terminal customization
```

## Contributing

Feel free to modify these scripts for your specific environment. When making changes:

1. Update hardcoded values for your network/domain
2. Test thoroughly before production use
3. Keep backups of original configurations

---

**Note**: These scripts are designed for development and testing environments. Review security implications before using in production.
