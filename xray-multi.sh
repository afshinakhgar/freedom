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

touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

if [[ "$ROLE" == "2" ]]; then
  ################################
  # Outside (Gateway)
  ################################

  UUID=$(uuidgen)

  cat > "$XRAY_DIR/config.json" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
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
  echo "VLESS Port: $VLESS_PORT"
  echo ""
  echo "Save UUID and use it on IRAN server"

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
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http","tls"]
      }
    },
    {
      "tag": "socks-in",
      "port": $SOCKS_PORT,
      "protocol": "socks",
      "settings": { "udp": true }
    },
    {
      "tag": "http-in",
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
          "users": [{
            "id": "$UUID",
            "encryption": "none"
          }]
        }]
      },
      "mux": {
        "enabled": true,
        "concurrency": 8
      }
    }
  ],

  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "vless-in",
          "socks-in",
          "http-in"
        ],
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
  echo "Server IP: $IRAN_IP"
  echo ""
  echo "----- VLESS (Mobile / v2rayN) -----"
  echo "vless://$UUID@$IRAN_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Iran-Relay"
  echo ""
  echo "----- SOCKS5 -----"
  echo "Address: $IRAN_IP"
  echo "Port   : $SOCKS_PORT"
  echo ""
  echo "----- HTTP Proxy -----"
  echo "Address: $IRAN_IP"
  echo "Port   : $HTTP_PORT"
fi

################################
# systemd
################################

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -c $XRAY_DIR/config.json
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
