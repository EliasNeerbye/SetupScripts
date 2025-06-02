# Files:
- change_network.sh
  - Sets your hostname and network based on input. Is hardcoded to use "10.12.90.X", so update this part if you want to use it for yourself.
- install_node.sh
  - Installs node via nvm. Use "source ~/.bashrc" after to get access to it.
- install_mongodb.sh
  - Installs mongodb and starts it's service. Use "source ~/.bashrc" if you want access to the "mongosh"
- setup_nginx.sh
  - Installs, sets up, and starts nginx. Has hardcoded config, meant for reverse proxy. Edit this if needed.
