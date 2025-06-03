# Server Setup Scripts

Bash scripts for quickly setting up Ubuntu servers with common development tools and services.

## Overview

Automates installation and configuration of Node.js, MongoDB, Nginx, and network settings for rapid deployment.

## Scripts

### Network Configuration

**`change_network.sh`**

-   Updates hostname and static IP address
-   Detects and modifies Netplan configuration
-   **Hardcoded for 10.12.90.X network**
-   Creates backup of original config
-   Requires root privileges

```bash
sudo ./change_network.sh
```

### Development Environment

**`install_node.sh`**

-   Installs Node.js via NVM
-   Installs latest LTS version
-   Sets up shell environment

```bash
./install_node.sh
source ~/.bashrc
```

**`install_mongodb.sh`**

-   Installs MongoDB Community Server 8.0
-   Configures and starts service
-   Enables automatic startup

```bash
./install_mongodb.sh
source ~/.bashrc
```

### Reverse Proxy

**`setup_nginx.sh`**

-   Installs and configures Nginx as reverse proxy
-   **Hardcoded for `userapi.harpy.ikt-fag.no` and `10.12.90.100`**
-   Proxies to `localhost:3000`
-   Requires root privileges

```bash
sudo ./setup_nginx.sh
```

### Security Configuration

**`setup_ufw.sh`**

-   Interactive UFW firewall configuration
-   Configures SSH, Nginx, MongoDB, and custom rules
-   Requires root privileges

```bash
sudo ./setup_ufw.sh
```

**`setup_match_blocks.sh`**

-   Configures SSH authentication per user/IP
-   Key-only auth for current user
-   Password + key auth for eksaminator
-   Password auth from trusted IPs
-   Requires root privileges

```bash
sudo ./setup_match_blocks.sh
```

### Terminal Customization

**`setup_login_greeting.sh`**

-   Creates `.hushlogin` to suppress system messages
-   Adds ASCII art greeting to `.bashrc`
-   Safe to run multiple times

```bash
./setup_login_greeting.sh
```

## Prerequisites

-   Ubuntu Server (tested on 22.04 LTS)
-   Internet connection
-   Root/sudo access for system scripts

## Quick Start

1. Make scripts executable: `chmod +x *.sh`
2. Run scripts as needed (see requirements above)
3. Reload shell after Node.js/MongoDB: `source ~/.bashrc`

## Important Notes

⚠️ **Hardcoded Values**: Review and modify these before use:

-   `change_network.sh`: Network range `10.12.90.X`
-   `setup_nginx.sh`: Domain `userapi.harpy.ikt-fag.no` and IP `10.12.90.100`

## File Structure

```md
.
├── README.md
├── change_network.sh # Network configuration
├── install_node.sh # Node.js installation
├── install_mongodb.sh # MongoDB installation
├── setup_nginx.sh # Nginx reverse proxy
├── setup_ufw.sh # UFW firewall
├── setup_match_blocks.sh # SSH authentication rules
└── setup_login_greeting.sh # Terminal customization
```

## Contributing

Modify hardcoded values for your environment and test before production use.
