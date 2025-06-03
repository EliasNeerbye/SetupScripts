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

### Database Security

**`setup_mongodb_auth.sh`**

-   Creates MongoDB admin user with root privileges
-   Enables authentication in MongoDB configuration
-   Configures IP binding for network access
-   Creates configuration backup
-   Requires root privileges

```bash
sudo ./setup_mongodb_auth.sh
```

### Application Deployment

**`deploy_api.sh`**

-   Clones Git repositories (supports GitHub URLs or repo names)
-   Automatically finds and installs Node.js dependencies
-   Interactive .env file setup from .env.example
-   Installs PM2 globally if not present
-   Starts applications with PM2 process management
-   Configures PM2 startup scripts

```bash
./deploy_api.sh
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
-   `deploy_api.sh`: Default GitHub base URL `https://github.com/EliasNeerbye/`

## Typical Deployment Workflow

1. **Initial Setup**: `sudo ./change_network.sh` (set hostname/IP)
2. **Install Stack**: `./install_node.sh` and `./install_mongodb.sh`
3. **Configure Security**: `sudo ./setup_ufw.sh` and `sudo ./setup_match_blocks.sh`
4. **Database Security**: `sudo ./setup_mongodb_auth.sh`
5. **Web Server**: `sudo ./setup_nginx.sh`
6. **Deploy Application**: `./deploy_api.sh`
7. **Customize Terminal**: `./setup_login_greeting.sh`

## File Structure

```md
.
├── README.md
├── change_network.sh # Network configuration
├── install_node.sh # Node.js installation
├── install_mongodb.sh # MongoDB installation
├── setup_mongodb_auth.sh # MongoDB authentication
├── deploy_api.sh # Application deployment
├── setup_nginx.sh # Nginx reverse proxy
├── setup_ufw.sh # UFW firewall
├── setup_match_blocks.sh # SSH authentication rules
└── setup_login_greeting.sh # Terminal customization
```

## Contributing

Modify hardcoded values for your environment and test before production use.
