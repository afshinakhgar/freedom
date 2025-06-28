#!/bin/bash

set -e

XRAY_DIR="/opt/xray"
VLESS_PORT=2096
WS_PATH="/"

mkdir -p $XRAY_DIR
apt update && apt install -y unzip curl

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Reverse Proxy Node)"
echo "2) 🌍 Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

echo "📥 Installing Xray..."
cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

mkdir -p /var/log/xray
touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

if [[ "$ROLE" == "2" ]]; then
  UUID=$(uuidgen)
  echo "🔧 Setting up OUTSIDE SERVER config..."
  cat > $XRAY_DIR/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WS_PATH"
        }
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ]
}
EOF

else
  read -rp "Enter OUTSIDE SERVER IP: " OUTSIDE_IP
  read -rp "Enter UUID (from OUTSIDE server): " UUID
  echo "🔧 Setting up IRAN REVERSE PROXY config..."
  cat > $XRAY_DIR/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": { "network": "tcp" }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$OUTSIDE_IP",
            "port": $VLESS_PORT,
            "users": [
              {
                "id": "$UUID",
                "encryption": "none"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "$WS_PATH"
        }
      }
    }
  ]
}
EOF
fi

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

echo ""
echo "✅ Xray install complete!"

if [[ "$ROLE" == "2" ]]; then
  SERVER_REAL_IP=$(curl -s https://api.ipify.org || hostname -I | cut -d' ' -f1)
  echo "Your UUID: $UUID"
  echo "🔗 VLESS CLIENT LINK:"
  echo "vless://$UUID@$SERVER_REAL_IP:$VLESS_PORT?security=none&encryption=none&type=ws&host=$SERVER_REAL_IP&path=$WS_PATH#IranAzad"
else
  echo "✅ Reverse proxy installed on Iran server. Connect your client to this server."
fi
