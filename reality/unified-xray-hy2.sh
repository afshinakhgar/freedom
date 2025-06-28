#!/bin/bash

# Iran Azad Unified Xray Reality + Hysteria2 Installer
# For both Iran (Client) and Outside (Server)
# Updated: 2025-06-27

set -e
echo "📦 Installing dependencies..."
apt update && apt install -y curl unzip tar openssl socat

echo ""
echo "🔧 Choose server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Server Node)"
read -rp "Choose 1 or 2: " ROLE

if [[ "$ROLE" == "2" ]]; then
  echo "🚀 Setting up Xray Reality Server..."
  XRAY_DIR="/opt/xray"
  mkdir -p $XRAY_DIR && cd $XRAY_DIR
  curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
  unzip -o xray.zip
  install -m 755 xray /usr/local/bin/xray

  UUID=$(uuidgen)
  REALITY_PRIVATE_KEY=$(xray x25519 | grep 'Private key' | awk '{print $3}')
  REALITY_PUBLIC_KEY=$(xray x25519 | grep 'Public key' | awk '{print $3}')

  cat > /opt/xray/config.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 443,
    "protocol": "vless",
    "settings": {
      "clients": [{"id": "$UUID", "flow": "xtls-rprx-vision"}],
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

  echo "🚀 Setting up Hysteria2 Server..."
  HY2_DIR="/opt/hysteria2"
  mkdir -p $HY2_DIR && cd $HY2_DIR
  curl -Lo hy2.tar.gz https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64.tar.gz
  tar -xzf hy2.tar.gz
  install -m 755 hysteria /usr/local/bin/hysteria

  PASSWORD=$(openssl rand -hex 8)

  cat > /etc/hysteria.yaml <<EOF
listen: :8443
obfs:
  password: "$PASSWORD"
auth:
  type: password
  password: "$PASSWORD"
tls:
  cert: /etc/ssl/certs/ssl-cert-snakeoil.pem
  key: /etc/ssl/private/ssl-cert-snakeoil.key
EOF

  cat > /etc/systemd/system/hysteria.service <<SERVICE
[Unit]
Description=Hysteria2 Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable hysteria
  systemctl restart hysteria

  SERVER_IP=$(curl -s https://api.ipify.org)
  echo ""
  echo "✅ Server setup complete!"
  echo "🌐 Server IP: $SERVER_IP"
  echo "🔑 Xray UUID: $UUID"
  echo "🔑 Xray Reality PublicKey: $REALITY_PUBLIC_KEY"
  echo "🛡 Hysteria2 Password: $PASSWORD"

elif [[ "$ROLE" == "1" ]]; then
  echo "🚀 Setting up Xray Reality Client..."
  read -rp "Enter FOREIGN SERVER IP: " SERVER_IP
  read -rp "Enter Xray UUID: " UUID
  read -rp "Enter Xray Reality PublicKey: " PUB_KEY

  XRAY_DIR="/opt/xray"
  mkdir -p $XRAY_DIR && cd $XRAY_DIR
  curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
  unzip -o xray.zip
  install -m 755 xray /usr/local/bin/xray

  cat > /opt/xray/client.json <<EOF
{
  "log": {
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": 1080,
    "protocol": "socks",
    "settings": {"udp": true}
  }],
  "outbounds": [{
    "protocol": "vless",
    "settings": {
      "vnext": [{
        "address": "$SERVER_IP",
        "port": 443,
        "users": [{
          "id": "$UUID",
          "flow": "xtls-rprx-vision",
          "encryption": "none"
        }]
      }]
    },
    "streamSettings": {
      "network": "tcp",
      "security": "reality",
      "realitySettings": {
        "serverName": "www.cloudflare.com",
        "publicKey": "$PUB_KEY",
        "shortId": "abcd1234",
        "fingerprint": "chrome"
      }
    }
  }]
}
EOF

  cat > /etc/systemd/system/xray-client.service <<SERVICE
[Unit]
Description=Xray Reality Client Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray -config /opt/xray/client.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable xray-client
  systemctl restart xray-client

  echo ""
  echo "🚀 Setting up Hysteria2 Client..."
  read -rp "Enter Hysteria2 Password: " HY2_PASS

  HY2_DIR="/opt/hysteria2"
  mkdir -p $HY2_DIR && cd $HY2_DIR
  curl -Lo hy2.tar.gz https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-amd64.tar.gz
  tar -xzf hy2.tar.gz
  install -m 755 hysteria /usr/local/bin/hysteria

  cat > /etc/hysteria-client.yaml <<EOF
server: $SERVER_IP:8443
obfs:
  password: "$HY2_PASS"
auth: "$HY2_PASS"
socks5:
  listen: 127.0.0.1:1081
insecure: true
EOF

  cat > /etc/systemd/system/hysteria-client.service <<SERVICE
[Unit]
Description=Hysteria2 Client Service
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria client -c /etc/hysteria-client.yaml
Restart=on-failure

[Install]
WantedBy=multi-user.target
SERVICE

  systemctl daemon-reload
  systemctl enable hysteria-client
  systemctl restart hysteria-client

  echo "✅ Client setup complete!"
else
  echo "❌ Invalid option. Please choose 1 or 2."
fi
