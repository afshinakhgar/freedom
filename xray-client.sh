#!/bin/bash

set -e

# نصب jq در صورت نیاز
if ! command -v jq &>/dev/null; then
  echo "📦 Installing jq..."
  apt update && apt install -y jq
fi

echo "📝 Enter OUTSIDE SERVER IP:"
read -rp "Server IP: " SERVER_IP

CONFIG_FILE="/opt/xray/config.json"
if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found at $CONFIG_FILE"
  exit 1
fi

echo "🔎 Found config file: $CONFIG_FILE"

UUID=$(jq -r '.inbounds[0].settings.clients[0].id' "$CONFIG_FILE")
TROJAN_PASS=$(jq -r '.inbounds[] | select(.protocol=="trojan").settings.clients[0].password' "$CONFIG_FILE")
VLESS_PORT=$(jq -r '.inbounds[] | select(.protocol=="vless").port' "$CONFIG_FILE")
VMESS_PORT=$(jq -r '.inbounds[] | select(.protocol=="vmess").port' "$CONFIG_FILE")
TROJAN_PORT=$(jq -r '.inbounds[] | select(.protocol=="trojan").port' "$CONFIG_FILE")

echo ""
echo "✅ Here are your clients:"
echo "Your UUID: $UUID"
echo "Your Trojan Password: $TROJAN_PASS"
echo ""
echo "vless://$UUID@$SERVER_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"
echo "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"IranAzad\",\"add\":\"$SERVER_IP\",\"port\":\"$VMESS_PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}" | base64 -w 0)"
echo "trojan://$TROJAN_PASS@$SERVER_IP:$TROJAN_PORT#IranAzad"
