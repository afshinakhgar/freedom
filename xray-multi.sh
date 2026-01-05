#!/bin/bash
set -e

XRAY_DIR="/opt/xray"
VLESS_PORT=4433
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

if [ ! -f xray ]; then
  curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
  unzip -o xray.zip
  install -m 755 xray /usr/local/bin/xray
fi

UUID_FILE="$XRAY_DIR/uuid"

if [[ "$ROLE" == "2" ]]; then
  ################################
  # Outside (Gateway)
  ################################

  UUID=$(uuidgen)
  echo "$UUID" > "$UUID_FILE"

  cat > "$XRAY_DIR/config.json" <<EOF
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
  echo "=============================="
  echo " OUTSIDE GATEWAY READY"
  echo "=============================="
  echo ""
  echo "Server IP : $SERVER_IP"
  echo "UUID      : $UUID"
  echo "Port      : $VLESS_PORT"
  echo ""
  echo "Save UUID for Iran server"

else
  ################################
  # Iran (Relay + Clients)
  ################################

  read -rp "Outside server IP: " OUTSIDE_IP
  read -rp "UUID (from outside): " UUID

  cat > "$XRAY_DIR/config.json" <<EOF
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
      "streamSettings": { "network": "tcp" },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      }
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
  echo "=============================="
  echo " IRAN RELAY READY"
  echo "=============================="
  echo ""
  echo "VLESS (Mobile / v2rayN):"
  echo "vless://$UUID@$IRAN_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Iran-Relay"
  echo ""
  echo "SOCKS5 (Local): 127.0.0.1:$SOCKS_PORT"
  echo "HTTP  (Local): 127.0.0.1:$HTTP_PORT"
fi

################################
# systemd service
################################

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
Description=Xray Service
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

echo ""
echo "=============================="
echo " Xray is running"
echo "=============================="
