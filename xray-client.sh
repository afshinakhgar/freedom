#!/bin/bash

set -e

XRAY_DIR="/opt/xray"
mkdir -p $XRAY_DIR
apt update && apt install -y unzip curl

echo "🌍 Enter server IP or domain:"
read -rp "Server IP: " SERVER_IP

echo "🔑 Enter UUID (VLESS / VMess):"
read -rp "UUID: " UUID

echo "🔑 Enter Trojan password (if using Trojan, leave empty otherwise):"
read -rp "Trojan Password: " TROJAN_PASS

echo "📦 Installing Xray..."
cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

echo "🔧 What protocol to use?"
echo "1) VLESS"
echo "2) VMess"
echo "3) Trojan"
read -rp "Choose 1/2/3: " PROTO_CHOICE

if [[ "$PROTO_CHOICE" == "1" ]]; then
  OUTBOUND=$(cat <<EOF
{
  "protocol": "vless",
  "settings": {
    "vnext": [
      {
        "address": "$SERVER_IP",
        "port": 2096,
        "users": [
          {
            "id": "$UUID",
            "encryption": "none"
          }
        ]
      }
    ]
  },
  "streamSettings": { "network": "tcp" }
}
EOF
)
elif [[ "$PROTO_CHOICE" == "2" ]]; then
  OUTBOUND=$(cat <<EOF
{
  "protocol": "vmess",
  "settings": {
    "vnext": [
      {
        "address": "$SERVER_IP",
        "port": 2087,
        "users": [
          {
            "id": "$UUID"
          }
        ]
      }
    ]
  },
  "streamSettings": { "network": "tcp" }
}
EOF
)
elif [[ "$PROTO_CHOICE" == "3" ]]; then
  OUTBOUND=$(cat <<EOF
{
  "protocol": "trojan",
  "settings": {
    "servers": [
      {
        "address": "$SERVER_IP",
        "port": 8443,
        "password": "$TROJAN_PASS"
      }
    ]
  },
  "streamSettings": { "network": "tcp" }
}
EOF
)
else
  echo "❌ Invalid choice"
  exit 1
fi

cat > $XRAY_DIR/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 1080,
      "protocol": "socks",
      "settings": { "udp": true }
    },
    {
      "port": 1081,
      "protocol": "http",
      "settings": {}
    }
  ],
  "outbounds": [
    $OUTBOUND
  ]
}
EOF

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
Description=Xray Client Service
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

echo ""
echo "✅ Xray client setup complete!"
echo "You can now use SOCKS5 at 127.0.0.1:1080 or HTTP proxy at 127.0.0.1:1081"
