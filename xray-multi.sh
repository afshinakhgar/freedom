#!/bin/bash
set -e

XRAY_DIR="/opt/xray"

VLESS_PORT=2096
VMESS_PORT=2087
TROJAN_PORT=8443
SOCKS_PORT=1080
HTTP_PORT=1081

mkdir -p "$XRAY_DIR" /var/log/xray
apt update && apt install -y unzip curl uuid-runtime openssl

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

UUID=$(uuidgen)
TROJAN_PASS=$(openssl rand -hex 8)

if [[ "$ROLE" == "2" ]]; then
  ################################
  # Outside (Gateway)
  ################################

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
  "outbounds": [{ "protocol": "freedom" }]
}
EOF

  echo ""
  echo "=============================="
  echo " OUTSIDE GATEWAY READY"
  echo "=============================="
  echo ""
  echo "Save these values for IRAN server:"
  echo ""
  echo "UUID: $UUID"
  echo "VLESS Port: $VLESS_PORT"

else
  ################################
  # Iran (Relay + Clients)
  ################################

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
      "port": $VLESS_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID" }],
        "decryption": "none"
      }
    },
    {
      "tag": "vmess-in",
      "port": $VMESS_PORT,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "$UUID" }]
      }
    },
    {
      "tag": "trojan-in",
      "port": $TROJAN_PORT,
      "protocol": "trojan",
      "settings": {
        "clients": [{ "password": "$TROJAN_PASS" }]
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
          "users": [{ "id": "$UUID", "encryption": "none" }]
        }]
      }
    }
  ],
  "routing": {
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "vless-in",
          "vmess-in",
          "trojan-in",
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
  echo " IRAN RELAY READY (ALL CLIENTS)"
  echo "=============================="
  echo ""
  echo "Server IP: $IRAN_IP"
  echo ""
  echo "----- VLESS -----"
  echo "vless://$UUID@$IRAN_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#Iran-All"
  echo ""
  echo "----- VMess -----"
  VMESS_JSON="{\"v\":\"2\",\"ps\":\"Iran-All\",\"add\":\"$IRAN_IP\",\"port\":\"$VMESS_PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"tls\":\"\"}"
  echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
  echo ""
  echo "----- Trojan -----"
  echo "trojan://$TROJAN_PASS@$IRAN_IP:$TROJAN_PORT#Iran-All"
  echo ""
  echo "----- SOCKS5 -----"
  echo "Address: $IRAN_IP"
  echo "Port:    $SOCKS_PORT"
  echo ""
  echo "----- HTTP Proxy -----"
  echo "Address: $IRAN_IP"
  echo "Port:    $HTTP_PORT"
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
