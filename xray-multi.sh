#!/bin/bash
set -e

XRAY_DIR="/opt/xray"
VLESS_PORT=2096
VMESS_PORT=2087

mkdir -p $XRAY_DIR /var/log/xray
apt update && apt install -y unzip curl uuid-runtime

echo "Server role:"
echo "1) Iran (Client Node)"
echo "2) Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

cd $XRAY_DIR
curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray

touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

if [[ "$ROLE" == "2" ]]; then
  UUID=$(uuidgen)

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
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "port": $VMESS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID" }]
      },
      "streamSettings": { "network": "tcp" }
    }
  ],
  "outbounds": [
    { "protocol": "freedom" }
  ]
}
EOF

  SERVER_IP=$(curl -s https://api.ipify.org)

  echo ""
  echo "UUID: $UUID"
  echo ""
  echo "VLESS:"
  echo "vless://$UUID@$SERVER_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Gateway"
  echo ""
  VMESS_JSON="{\"v\":\"2\",\"ps\":\"Gateway\",\"add\":\"$SERVER_IP\",\"port\":\"$VMESS_PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}"
  echo "VMess:"
  echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"

else
  read -rp "Outside server IP: " SERVER_IP
  read -rp "UUID: " UUID

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
      "protocol": "http"
    }
  ],
  "outbounds": [
    {
      "tag": "vless-out",
      "protocol": "vless",
      "settings": {
        "vnext": [{
          "address": "$SERVER_IP",
          "port": $VLESS_PORT,
          "users": [{ "id": "$UUID", "encryption": "none" }]
        }]
      }
    },
    {
      "tag": "vmess-out",
      "protocol": "vmess",
      "settings": {
        "vnext": [{
          "address": "$SERVER_IP",
          "port": $VMESS_PORT,
          "users": [{ "id": "$UUID" }]
        }]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": ["socks"],
        "outboundTag": "vless-out"
      }
    ]
  }
}
EOF
fi

cat > /etc/systemd/system/xray.service <<SERVICE
[Unit]
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

echo "Xray is running"
