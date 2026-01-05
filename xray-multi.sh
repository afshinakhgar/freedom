#!/bin/bash
set -e

XRAY_DIR="/opt/xray"
VLESS_PORT=2096
WS_PATH="/"

mkdir -p "$XRAY_DIR" /var/log/xray
apt update && apt install -y unzip curl uuid-runtime

echo "=============================="
echo " Select server role"
echo "=============================="
echo "1) Iran (Relay)"
echo "2) Outside (Gateway)"
read -rp "Choose 1 or 2: " ROLE

cd "$XRAY_DIR"

# Install xray if not exists
if [ ! -f /usr/local/bin/xray ]; then
  curl -Lo xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
  unzip -o xray.zip
  install -m 755 xray /usr/local/bin/xray
fi

touch /var/log/xray/access.log /var/log/xray/error.log
chmod 644 /var/log/xray/*.log

if [[ "$ROLE" == "2" ]]; then
  ############################
  # Outside (Gateway - WS)
  ############################

  UUID=$(uuidgen)

  cat > "$XRAY_DIR/config.json" <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "listen": "0.0.0.0",
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
    { "protocol": "freedom" }
  ]
}
EOF

  SERVER_IP=$(curl -s https://api.ipify.org)

  echo ""
  echo "===== OUTSIDE READY ====="
  echo "Server IP : $SERVER_IP"
  echo "UUID      : $UUID"
  echo "Port      : $VLESS_PORT"
  echo "WS Path   : $WS_PATH"
  echo "========================"
  echo "👉 Save UUID for IRAN server"

else
  ############################
  # Iran (Relay - TCP → WS)
  ############################

  read -rp "Outside server IP: " OUTSIDE_IP
  read -rp "UUID (from outside): " UUID

  cat > "$XRAY_DIR/config.json" <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "tag": "vless-in",
      "listen": "0.0.0.0",
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "to-outside",
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

  IRAN_IP=$(curl -s https://api.ipify.org)

  echo ""
  echo "===== IRAN RELAY READY ====="
  echo ""
  echo "Use this VLESS link on clients:"
  echo ""
  echo "vless://$UUID@$IRAN_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Iran-Relay"
  echo "============================"
fi

############################
# systemd service
############################

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
