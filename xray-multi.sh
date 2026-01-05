#!/bin/bash
set -e

XRAY_DIR="/opt/xray"
VLESS_PORT=2096
SOCKS_PORT=1080
HTTP_PORT=1081

mkdir -p "$XRAY_DIR" /var/log/xray
apt update && apt install -y unzip curl uuid-runtime

echo "=============================="
echo " Select server role"
echo "=============================="
echo "1) Iran (Relay + Clients)"
echo "2) Outside (Gateway)"
read -rp "Choose 1 or 2: " ROLE

cd "$XRAY_DIR"
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

if [[ "$ROLE" == "2" ]]; then
  # ===== Outside =====
  UUID=$(uuidgen)

  cat > config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "streamSettings": { "network": "tcp" }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

  SERVER_IP=$(curl -s https://api.ipify.org)

  echo ""
  echo "===== OUTSIDE READY ====="
  echo "Server IP : $SERVER_IP"
  echo "UUID      : $UUID"
  echo "Port      : $VLESS_PORT"
  echo "========================"

else
  # ===== Iran =====
  read -rp "Outside server IP: " OUTSIDE_IP
  read -rp "UUID (from outside): " UUID

  cat > config.json <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "vless-in",
      "listen": "0.0.0.0",
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "tag": "socks-in",
      "listen": "127.0.0.1",
      "port": $SOCKS_PORT,
      "protocol": "socks",
      "settings": { "udp": true }
    },
    {
      "tag": "http-in",
      "listen": "127.0.0.1",
      "port": $HTTP_PORT,
      "protocol": "http"
    }
  ],
  "outbounds": [
    {
      "tag": "to-outside",
      "protocol": "vless",
      "settings": {
        "vnext": [{
          "address": "$OUTSIDE_IP",
          "port": $VLESS_PORT,
          "users": [{ "id": "$UUID", "encryption": "none" }]
        }]
      },
      "streamSettings": { "network": "tcp" }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["vless-in","socks-in","http-in"],
        "outboundTag": "to-outside"
      }
    ]
  }
}
EOF

  IRAN_IP=$(curl -s https://api.ipify.org)

  echo ""
  echo "===== IRAN READY ====="
  echo "VLESS:"
  echo "vless://$UUID@$IRAN_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Iran-Relay"
  echo "SOCKS5: 127.0.0.1:$SOCKS_PORT"
  echo "HTTP  : 127.0.0.1:$HTTP_PORT"
  echo "====================="
fi

# systemd
cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
After=network.target
[Service]
ExecStart=/usr/local/bin/xray -config $XRAY_DIR/config.json
Restart=always
LimitNOFILE=1048576
[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xray --now

echo "Xray is running"
