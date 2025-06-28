#!/bin/bash

set -e

XRAY_DIR="/opt/xray"
UUID=$(uuidgen)
VLESS_PORT=2096
VMESS_PORT=2087
TROJAN_PORT=8443
TROJAN_PASS="$(openssl rand -hex 8)"

mkdir -p $XRAY_DIR
apt update && apt install -y unzip curl

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

echo "📥 Installing Xray..."
cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

if [[ "$ROLE" == "2" ]]; then
  echo "🔧 Setting up SERVER config..."
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
    },
    {
      "port": $VMESS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ]
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "port": $TROJAN_PORT,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$TROJAN_PASS" }
        ]
      },
      "streamSettings": { "network": "tcp" }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ]
}
EOF

else
  read -rp "Enter OUTSIDE SERVER IP: " SERVER_IP
  echo "🔧 Setting up CLIENT config..."
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
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_IP",
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
      "streamSettings": { "network": "tcp" }
    },
    {
      "protocol": "vmess",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_IP",
            "port": $VMESS_PORT,
            "users": [
              {
                "id": "$UUID"
              }
            ]
          }
        ]
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "protocol": "trojan",
      "settings": {
        "servers": [
          {
            "address": "$SERVER_IP",
            "port": $TROJAN_PORT,
            "password": "$TROJAN_PASS"
          }
        ]
      },
      "streamSettings": { "network": "tcp" }
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
  echo "Your Trojan Password: $TROJAN_PASS"
  echo "vless://$UUID@$SERVER_REAL_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"
  echo "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"IranAzad\",\"add\":\"$SERVER_REAL_IP\",\"port\":\"$VMESS_PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}" | base64 -w 0)"
  echo "trojan://$TROJAN_PASS@$SERVER_REAL_IP:$TROJAN_PORT#IranAzad"
else
  echo "✅ On CLIENT: configure your apps to use SOCKS5 127.0.0.1:1080 or HTTP 127.0.0.1:1081."
fi
