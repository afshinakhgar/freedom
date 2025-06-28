#!/bin/bash

# ===============================================
# Iran Azad OpenVPN Site-to-Site TCP Installer
# Supports: OpenVPN TCP tunnel Iran <-> Outside
# For: Ubuntu 22.04+
# Updated: 2025-06-27
# ===============================================

OVPN_DIR="/etc/openvpn"
OVPN_PORT=443
OVPN_NET="10.88.0.0 255.255.255.0"

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Server Node)"
read -rp "Choose 1 or 2: " ROLE

echo "🔨 Installing OpenVPN..."
apt update && apt install -y openvpn easy-rsa

mkdir -p /etc/openvpn/ccd

if [[ "$ROLE" == "2" ]]; then
  echo "🛠 Configuring OpenVPN Server..."

  # Generate server keys
  cd $OVPN_DIR
  [ ! -f ca.crt ] && \
  openvpn --genkey --secret ta.key && \
  openssl req -new -nodes -x509 -keyout server.key -out server.crt -subj "/CN=OpenVPN-Server" -days 3650
  
  cat > $OVPN_DIR/server.conf <<EOF
port $OVPN_PORT
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh none
server $OVPN_NET
ifconfig-pool-persist ipp.txt
client-config-dir ccd
route 0.0.0.0 0.0.0.0
keepalive 10 120
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF

  systemctl enable openvpn@server
  systemctl start openvpn@server

  echo "✅ OpenVPN server installed on port TCP/$OVPN_PORT"

elif [[ "$ROLE" == "1" ]]; then
  read -rp "Enter PUBLIC IP of FOREIGN server: " REMOTE_IP

  echo "🛠 Configuring OpenVPN Client..."

  cd $OVPN_DIR
  [ ! -f ca.crt ] && \
  openssl req -new -nodes -x509 -keyout client.key -out client.crt -subj "/CN=OpenVPN-Client" -days 3650
  
  cat > $OVPN_DIR/client.conf <<EOF
client
dev tun
proto tcp
remote $REMOTE_IP $OVPN_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
cert client.crt
key client.key
verb 3
EOF

  systemctl enable openvpn@client
  systemctl start openvpn@client

  echo "✅ OpenVPN client installed connecting to $REMOTE_IP:$OVPN_PORT"

else
  echo "❌ Invalid role."
  exit 1
fi
