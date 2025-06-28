#!/bin/bash

# Iran Azad Xray Reality Installer
# Updated: 2025-06-27

echo "📦 Installing dependencies..."
apt update && apt install -y curl unzip socat

XRAY_DIR="/opt/xray"
mkdir -p $XRAY_DIR && cd $XRAY_DIR

echo "📥 Downloading Xray..."
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

echo "🔧 Configuring Xray Reality..."
UUID=$(uuidgen)
REALITY_PRIVATE_KEY=$(xray x25519 | grep 'Private key' | awk '{print $3}')
REALITY_PUBLIC_KEY=$(xray x25519 | grep 'Public key' | awk '{print $3}')

cat > /opt/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{
        "id": "$UUID",
        "flow": "xtls-rprx-vision"
      }],
      "decryption": "none"
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "show": false,
        "dest": "www.cloudflare.com:443",
        "xver": 0,
        "privateKey": "$REALITY_PRIVATE_KEY",
        "shortIds": ["abcd1234"]
      }
    }
  }],
  "outbounds": [{"protocol": "freedom"}]
}
EOF

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -config /opt/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable xray
systemctl restart xray

echo ""
echo "✅ Xray Reality setup complete!"
echo "Your VLESS UUID: $UUID"
echo "Your Reality PublicKey: $REALITY_PUBLIC_KEY"
