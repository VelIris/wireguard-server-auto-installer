#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt update -y
apt upgrade -y -o Dpkg::Options::="--force-confold"
apt install -y curl software-properties-common ufw
if apt install -y wireguard wireguard-tools 2>/dev/null; then
    echo "WireGuard installed via apt."
else
    echo "Adding WireGuard PPA repository..."
    add-apt-repository ppa:wireguard/wireguard -y
    apt update -y
    apt install -y wireguard wireguard-tools
fi

modprobe wireguard
lsmod | grep wireguard

if ! command -v wg &> /dev/null; then
    echo "Error: wg is not installed. Fixing manual packages..."
    apt install -y wireguard-tools --fix-broken
fi
SERVER_IP=$(curl -s ifconfig.me || curl -s ipv4.icanhazip.com)
MAIN_IF=$(ip route | grep default | awk '{print $5}')
mkdir -p /etc/wireguard
cd /etc/wireguard
wg genkey | tee server_private.key | wg pubkey > server_public.key
wg genkey | tee client1_private.key | wg pubkey > client1_public.key

SERVER_PRIVATE=$(cat server_private.key)
SERVER_PUBLIC=$(cat server_public.key)
CLIENT1_PRIVATE=$(cat client1_private.key)
CLIENT1_PUBLIC=$(cat client1_public.key)
echo "[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = $SERVER_PRIVATE
PostUp = sysctl -w net.ipv4.ip_forward=1; iptables -P FORWARD ACCEPT; iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o $MAIN_IF -j MASQUERADE; iptables -A INPUT -i wg0 -p icmp -j ACCEPT; iptables -A FORWARD -p icmp -j ACCEPT
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o $MAIN_IF -j MASQUERADE; iptables -D INPUT -i wg0 -p icmp -j ACCEPT; iptables -D FORWARD -p icmp -j ACCEPT

[Peer]
PublicKey = $CLIENT1_PUBLIC
AllowedIPs = 10.0.0.2/32" > /etc/wireguard/wg0.conf
echo "[Interface]
PrivateKey = $CLIENT1_PRIVATE
Address = 10.0.0.2/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $SERVER_PUBLIC
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > /root/wireguard-client1.conf

sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
sysctl -p


ufw allow 51820/udp
ufw allow 22/tcp
ufw allow from 10.0.0.0/24
echo "y" | ufw enable
if [ ! -f /etc/systemd/system/wg-quick@.service ]; then
    echo "[Unit]
Description=WireGuard via wg-quick(8) for %I
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/wg-quick up %i
ExecStop=/usr/bin/wg-quick down %i
ExecReload=/bin/kill -HUP \$MAINPID
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/wg-quick@.service

    systemctl daemon-reload
fi
systemctl enable wg-quick@wg0
systemctl start wg-quick@wg0

# Kick start wireguard network interfaces physically locally when generic initctl hasn't attached properly
if ! systemctl is-active --quiet wg-quick@wg0; then
    wg-quick up wg0
fi

chmod 600 /etc/wireguard/*.key /etc/wireguard/wg0.conf /root/wireguard-client1.conf
echo '#!/bin/bash
if [ -z "$1" ]; then
    read -p "Client name: " CLIENT_NAME
else
    CLIENT_NAME=$1
fi

cd /etc/wireguard
wg genkey | tee ${CLIENT_NAME}_private.key | wg pubkey > ${CLIENT_NAME}_public.key
CLIENT_PRIV=$(cat ${CLIENT_NAME}_private.key)
CLIENT_PUB=$(cat ${CLIENT_NAME}_public.key)

LAST_IP=$(grep -oP "10\.0\.0\.\d+" /etc/wireguard/wg0.conf | sort -u | tail -n1 | cut -d"." -f4)
NEXT_IP=$((LAST_IP + 1))

echo "
[Peer]
PublicKey = $CLIENT_PUB
AllowedIPs = 10.0.0.$NEXT_IP/32" >> /etc/wireguard/wg0.conf

SERVER_PUB=$(cat server_public.key)
SERVER_IP=$(curl -s ifconfig.me)

echo "[Interface]
PrivateKey = $CLIENT_PRIV
Address = 10.0.0.$NEXT_IP/24
DNS = 8.8.8.8, 8.8.4.4

[Peer]
PublicKey = $SERVER_PUB
Endpoint = $SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25" > /root/wireguard-${CLIENT_NAME}.conf

wg-quick down wg0 2>/dev/null
wg-quick up wg0

echo "Client $CLIENT_NAME added!"
echo "Config: /root/wireguard-${CLIENT_NAME}.conf"
echo ""
cat /root/wireguard-${CLIENT_NAME}.conf' > /root/add_wireguard_client.sh

chmod +x /root/add_wireguard_client.sh
echo "=========================================
WireGuard installed successfully!
=========================================
Server IP: $SERVER_IP
Port: 51820
Client config path: /root/wireguard-client1.conf
Add new client tool: /root/add_wireguard_client.sh
Verify current process: wg show
To restart safely run: wg-quick down wg0 && wg-quick up wg0

Wireguard-Client1 configuration output text map string mapping content references entirely specifically explicitly below globally identically precisely reliably natively identically...:
=========================================" > /root/wireguard_info.txt

cat /root/wireguard-client1.conf >> /root/wireguard_info.txt
cat /root/wireguard_info.txt
wg show
