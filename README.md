WireGuard Auto Installer for Ubuntu
A fully automated WireGuard VPN deployment script for Ubuntu servers.
The script installs and configures a WireGuard VPN server, enables IP forwarding, configures NAT routing, sets up UFW firewall rules, generates cryptographic keys, creates the first VPN client, and provides a utility for adding additional clients.

Features

- Automatic WireGuard installation
- Automatic server and client key generation
- UFW firewall configuration
- IP forwarding configuration
- NAT routing setup
- Automatic systemd service configuration
- First client configuration generation
- Unlimited client creation support
- Ubuntu server deployment in a single command

Supported Operating Systems

- Ubuntu 20.04 LTS
- Ubuntu 22.04 LTS
- Ubuntu 24.04 LTS

Installation

Download the script:
wget https://raw.githubusercontent.com/veliris/wireguard-server-auto-installer/main/install.sh

Make it executable:
chmod +x install.sh

Run the installer:
sudo ./install.sh


Generated Files:
1. Server Configuration
/etc/wireguard/wg0.conf
2. Server Keys
/etc/wireguard/server_private.key
/etc/wireguard/server_public.key
3. First Client Configuration
/root/wireguard-client1.conf
4. Client Creation Utility
/root/add_wireguard_client.sh
5. Installation Summary
/root/wireguard_info.txt



The generated client configuration works with:
WireGuard for Windows
WireGuard for Linux
WireGuard for macOS
WireGuard for Android
WireGuard for iOS


Default Network Configuration
| Parameter            | Value       |
| -------------------- | ----------- |
| VPN Network          | 10.0.0.0/24 |
| Server VPN Address   | 10.0.0.1    |
| First Client Address | 10.0.0.2    |
| WireGuard Port       | 51820/UDP   |
