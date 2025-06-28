#!/bin/bash

# ===============================================
# Iran Azad VPN Dual-Node Installer (Auto AllowedIPs Switch + UDP Port Scanner)
# Supports: WireGuard + Xray (VLESS + VMess + Shadowsocks + Trojan)
# Updated: 2025-06-27
# ===============================================

WG_DIR="/etc/wireguard"
XRAY_DIR="/opt/xray"
WG_INTERFACE="wg0"
WG_PORT=51820
WG_NET="10.66.66.0/24"
WG_IP_IR="10.66.66.2"
WG_IP_OUT="10.66.66.1"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"
IF_EXT="$(ip route get 1 | awk '{print $5; exit}')"
UUID="1a7e9fcd-877f-4d2f-8c80-2d4469b0be1e"
VMESS_UUID=$(uuidgen)
SHADOW_PASS="$(openssl rand -hex 8)"
TROJAN_PASS="$(openssl rand -hex 8)"
VLESS_PORT=2096
VMESS_PORT=2087
SHADOW_PORT=8388
TROJAN_PORT=8443

mkdir -p $WG_DIR $XRAY_DIR
apt update && apt install -y unzip curl iptables-persistent resolvconf

mkdir -p /var/log/xray
chmod 755 /var/log/xray
touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

echo "⚙️  Install WireGuard?"
echo "1) Internet (apt install)"
echo "2) Offline (.deb files)"
echo "3) Skip"
read -rp "Choose 1/2/3: " WGINSTALL

if [[ "$WGINSTALL" == "1" ]]; then
  apt update && apt install -y wireguard
elif [[ "$WGINSTALL" == "2" ]]; then
  dpkg -i ./wireguard*.deb || apt --fix-broken install -y
else
  echo "⚠️  Skipping WireGuard install"
fi

umask 077
cd $WG_DIR || exit 1
[[ ! -f privatekey ]] && wg genkey | tee privatekey | wg pubkey > publickey
PRIVKEY=$(cat privatekey)
PUBKEY=$(cat publickey)

if [[ "$ROLE" == "1" ]]; then
  echo "🔐 Your public key: $PUBKEY"
  read -rp "Enter public key of FOREIGN server: " PEER_PUB
  read -rp "Enter IP/domain of FOREIGN server: " PEER_IP

  echo "🔍 Scanning UDP ports for outgoing connectivity..."
  PORTS_TO_TEST=(51820 53 123 1194 443 8080 20000 30000 40000 50000)
  FOUND_PORT=""
  for p in "${PORTS_TO_TEST[@]}"; do
    echo -n "Testing UDP port $p... "
    if timeout 1 bash -c "</dev/udp/$PEER_IP/$p" &>/dev/null; then
      echo "✅ Open"
      FOUND_PORT=$p
      break
    else
      echo "❌ Closed"
    fi
  done

  if [[ -z "$FOUND_PORT" ]]; then
    echo "❌ No open UDP port found. Exiting."
    exit 1
  else
    WG_PORT=$FOUND_PORT
    echo "✅ Using UDP port $WG_PORT for WireGuard"
  fi

  cat > $WG_CONF <<EOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WG_IP_IR/24
DNS = 1.1.1.1
ListenPort = $WG_PORT

[Peer]
PublicKey = $PEER_PUB
Endpoint = $PEER_IP:$WG_PORT
AllowedIPs = 8.8.8.8/32
PersistentKeepalive = 25
EOF

  systemctl enable wg-quick@$WG_INTERFACE
  systemctl restart wg-quick@$WG_INTERFACE

  echo "🔧 Setting up failover check script..."
  cat > /usr/local/bin/failover-check.sh <<'EOF'
#!/bin/bash
WG_INTERFACE="wg0"
WG_CONF="/etc/wireguard/${WG_INTERFACE}.conf"

LAST_HANDSHAKE=$(wg show $WG_INTERFACE latest-handshakes | awk '{print $2}')
NOW=$(date +%s)

if [[ -z "$LAST_HANDSHAKE" || "$LAST_HANDSHAKE" -eq 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | No handshake info. Skipping."
  exit 0
fi

DIFF=$((NOW - LAST_HANDSHAKE))

if [[ $DIFF -le 30 ]]; then
  if grep -q "AllowedIPs = 8.8.8.8/32" "$WG_CONF"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Handshake OK. Updating AllowedIPs to full tunnel."
    sed -i "s|AllowedIPs = .*|AllowedIPs = 0.0.0.0/1, 128.0.0.0/1|" "$WG_CONF"
    wg syncconf $WG_INTERFACE <(wg-quick strip $WG_INTERFACE)
  fi
  exit 0
fi

if [[ $DIFF -gt 60 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | No handshake for $DIFF sec. Bringing down $WG_INTERFACE."
  wg-quick down $WG_INTERFACE
fi
EOF

  chmod +x /usr/local/bin/failover-check.sh
  (crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/failover-check.sh") | crontab -

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

echo "📦 Installing Xray..."
cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

cat > $XRAY_DIR/config.json <<XRAY
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {"clients":[{"id":"$UUID"}],"decryption":"none"},
      "streamSettings": {"network":"tcp","security":"none"}
    },
    {"port":$VMESS_PORT,"protocol":"vmess","settings":{"clients":[{"id":"$VMESS_UUID","alterId":0}]},"streamSettings":{"network":"tcp","security":"none"}},
    {"port":$SHADOW_PORT,"protocol":"shadowsocks","settings":{"method":"aes-128-gcm","password":"$SHADOW_PASS","network":"tcp,udp"}},
    {"port":$TROJAN_PORT,"protocol":"trojan","settings":{"clients":[{"password":"$TROJAN_PASS"}]},"streamSettings":{"network":"tcp"}}
  ],
  "outbounds":[{"protocol":"freedom","settings":{}}]
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

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

echo ""
echo "✅ Install complete!"
echo "Your VLESS UUID: $UUID"
echo "Your VMess UUID: $VMESS_UUID"
echo "Shadowsocks Password: $SHADOW_PASS"
echo "Trojan Password: $TROJAN_PASS"
SERVER_REAL_IP=$(curl -s https://api.ipify.org || hostname -I | cut -d" " -f1)
echo "vless://$UUID@$SERVER_REAL_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"

VMESS_JSON=$(cat <<EOF
{"v":"2","ps":"IranAzad","add":"$SERVER_REAL_IP","port":"$VMESS_PORT","id":"$VMESS_UUID","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
EOF
)

echo "vmess://$(echo "$VMESS_JSON" | base64 -w 0)"
echo "ss://$(echo -n "aes-128-gcm:$SHADOW_PASS@$SERVER_REAL_IP:$SHADOW_PORT" | base64 -w 0)#IranAzad"
echo "trojan://$TROJAN_PASS@$SERVER_REAL_IP:$TROJAN_PORT#IranAzad"
