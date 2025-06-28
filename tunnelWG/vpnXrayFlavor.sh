#!/bin/bash

# ===============================================
# Iran Azad Unified Installer
# Supports: WireGuard | OpenVPN-TCP | WireGuard over udp2raw
# Plus: Xray (VLESS/VMess/Shadowsocks/Trojan) + failover-check
# For: Ubuntu 22.04+
# Updated: 2025-06-27
# ===============================================

WG_DIR="/etc/wireguard"
OVPN_DIR="/etc/openvpn"
XRAY_DIR="/opt/xray"
WG_INTERFACE="wg0"
WG_PORT=51820
WG_NET="10.66.66.0/24"
WG_IP_IR="10.66.66.2"
WG_IP_OUT="10.66.66.1"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"
IF_EXT="$(ip route get 1 | awk '{print $5; exit}')"
UUID=$(uuidgen)
VMESS_UUID=$(uuidgen)
SHADOW_PASS=$(openssl rand -hex 8)
TROJAN_PASS=$(openssl rand -hex 8)
VLESS_PORT=2096
VMESS_PORT=2087
SHADOW_PORT=8388
TROJAN_PORT=8443

mkdir -p $WG_DIR $XRAY_DIR
apt update && apt install -y unzip curl iptables-persistent resolvconf easy-rsa openvpn wireguard

echo "🔧 Select VPN type:"
echo "1) WireGuard (Default)"
echo "2) OpenVPN on TCP/443"
echo "3) WireGuard over udp2raw (UDP->TCP tunnel)"
read -rp "Choose 1/2/3: " VPN_TYPE

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

if [[ "$VPN_TYPE" == "2" ]]; then
  echo "🛠 Setting up OpenVPN..."
  if [[ "$ROLE" == "2" ]]; then
    cd $OVPN_DIR
    openvpn --genkey --secret ta.key
    openssl req -new -nodes -x509 -keyout server.key -out server.crt -subj "/CN=OpenVPN-Server" -days 3650
    cat > server.conf <<EOF
port 443
proto tcp
dev tun
ca server.crt
cert server.crt
key server.key
dh none
ifconfig-pool-persist ipp.txt
server 10.88.0.0 255.255.255.0
keepalive 10 120
persist-key
persist-tun
status openvpn-status.log
verb 3
EOF
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
    sysctl --system
    iptables -t nat -A POSTROUTING -s 10.88.0.0/24 -o $IF_EXT -j MASQUERADE
    netfilter-persistent save
    systemctl enable openvpn@server
    systemctl restart openvpn@server
    echo "✅ OpenVPN server up on TCP/443."
  elif [[ "$ROLE" == "1" ]]; then
    read -rp "Enter PUBLIC IP of FOREIGN server: " REMOTE_IP
    cd $OVPN_DIR
    cat > client.conf <<EOF
client
dev tun
proto tcp
remote $REMOTE_IP 443
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
EOF
    systemctl enable openvpn@client
    systemctl restart openvpn@client
    echo "✅ OpenVPN client configured for $REMOTE_IP:443."
  fi
fi

if [[ "$VPN_TYPE" == "3" ]]; then
  echo "🛠 Setting up udp2raw..."
  curl -Lo /usr/local/bin/udp2raw https://github.com/wangyu-/udp2raw-tunnel/releases/latest/download/udp2raw_binaries.tar.gz
  tar -xzf udp2raw_binaries.tar.gz -C /usr/local/bin
  chmod +x /usr/local/bin/udp2raw_amd64
  echo "🔧 Starting udp2raw..."
  if [[ "$ROLE" == "2" ]]; then
    nohup /usr/local/bin/udp2raw_amd64 -s -l0.0.0.0:443 -r127.0.0.1:$WG_PORT -k secretpass --raw-mode faketcp -a > /var/log/udp2raw.log 2>&1 &
  else
    read -rp "Enter PUBLIC IP of FOREIGN server: " REMOTE_IP
    nohup /usr/local/bin/udp2raw_amd64 -c -l127.0.0.1:1055 -r$REMOTE_IP:443 -k secretpass --raw-mode faketcp -a > /var/log/udp2raw.log 2>&1 &
    WG_ENDPOINT="127.0.0.1:1055"
  fi
fi

# WireGuard setup
umask 077
cd $WG_DIR || exit 1
[[ ! -f privatekey ]] && wg genkey | tee privatekey | wg pubkey > publickey
PRIVKEY=$(cat privatekey)
PUBKEY=$(cat publickey)

if [[ "$ROLE" == "1" ]]; then
  echo "🔐 Your public key: $PUBKEY"
  read -rp "Enter public key of FOREIGN server: " PEER_PUB
  [[ -z "$WG_ENDPOINT" ]] && read -rp "Enter IP/domain of FOREIGN server: " PEER_IP
  WG_ENDPOINT="${WG_ENDPOINT:-$PEER_IP:$WG_PORT}"
  cat > $WG_CONF <<EOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WG_IP_IR/24
DNS = 1.1.1.1
ListenPort = $WG_PORT
[Peer]
PublicKey = $PEER_PUB
Endpoint = $WG_ENDPOINT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF
  systemctl enable wg-quick@$WG_INTERFACE
  systemctl restart wg-quick@$WG_INTERFACE

elif [[ "$ROLE" == "2" ]]; then
  echo "🔐 Your public key: $PUBKEY"
  read -rp "Enter public key of IRAN server: " PEER_PUB
  cat > $WG_CONF <<EOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WG_IP_OUT/24
ListenPort = $WG_PORT
PostUp = iptables -t nat -A POSTROUTING -s $WG_NET -o $IF_EXT -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s $WG_NET -o $IF_EXT -j MASQUERADE
[Peer]
PublicKey = $PEER_PUB
AllowedIPs = $WG_IP_IR/32
EOF
  echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-forward.conf
  sysctl --system
  systemctl enable wg-quick@$WG_INTERFACE
  systemctl restart wg-quick@$WG_INTERFACE
fi

# Xray install
echo "📦 Installing Xray..."
mkdir -p $XRAY_DIR
cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

cat > $XRAY_DIR/config.json <<XRAY
{
  "log": { "loglevel": "warning", "access": "/var/log/xray/access.log", "error": "/var/log/xray/error.log" },
  "inbounds": [
    { "port": $VLESS_PORT, "protocol": "vless", "settings": { "clients": [{ "id": "$UUID" }], "decryption": "none" }, "streamSettings": { "network": "tcp", "security": "none" }},
    { "port": $VMESS_PORT, "protocol": "vmess", "settings": { "clients": [{ "id": "$VMESS_UUID", "alterId": 0 }] }, "streamSettings": { "network": "tcp", "security": "none" }},
    { "port": $SHADOW_PORT, "protocol": "shadowsocks", "settings": { "method": "aes-128-gcm", "password": "$SHADOW_PASS" }},
    { "port": $TROJAN_PORT, "protocol": "trojan", "settings": { "clients": [{ "password": "$TROJAN_PASS" }] }, "streamSettings": { "network": "tcp" }}
  ],
  "outbounds": [{ "protocol": "freedom", "settings": {} }]
}
XRAY

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
Description=Xray Service
After=network.target
[Service]
ExecStart=/usr/local/bin/xray -config $XRAY_DIR/config.json
Restart=on-failure
[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# Failover script
echo "🔧 Setting up failover check script..."
cat > /usr/local/bin/failover-check.sh <<'EOF'
#!/bin/bash
PEER_IP="8.8.8.8"
if ! ping -c 2 $PEER_IP &>/dev/null; then
  systemctl restart wg-quick@wg0
fi
EOF

chmod +x /usr/local/bin/failover-check.sh
(crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/failover-check.sh") | crontab -

SERVER_REAL_IP=$(curl -s https://api.ipify.org || hostname -I | cut -d" " -f1)

echo ""
echo "✅ Install complete"
echo "Your PUBLIC KEY: $PUBKEY"
echo "WireGuard client config:"
echo "[Interface]"
echo "PrivateKey = $PRIVKEY"
echo "Address = $WG_IP_IR/24"
echo "DNS = 1.1.1.1"
echo ""
echo "[Peer]"
echo "PublicKey = $PEER_PUB"
echo "Endpoint = ${WG_ENDPOINT:-$SERVER_REAL_IP:$WG_PORT}"
echo "AllowedIPs = 0.0.0.0/0"
echo "PersistentKeepalive = 25"

