#!/bin/bash

set -e

CONFIG="/opt/xray/config.json"
UUID=""
TROJAN_PASS=""

echo "📝 Enter OUTSIDE SERVER IP:"
read -rp "Server IP: " SERVER_IP

if [[ -f "$CONFIG" ]]; then
  echo "🔎 Found config file: $CONFIG"
  UUID=$(jq -r '.inbounds[] | select(.protocol=="vless") | .settings.clients[0].id' "$CONFIG")
  TROJAN_PASS=$(jq -r '.inbounds[] | select(.protocol=="trojan") | .settings.clients[0].password' "$CONFIG")
  echo "✅ Read UUID: $UUID"
  echo "✅ Read Trojan Password: $TROJAN_PASS"
else
  echo "⚠️ No config file found. Please enter manually."
  read -rp "UUID: " UUID
  read -rp "Trojan Password: " TROJAN_PASS
fi

VLESS_PORT=2096
VMESS_PORT=2087
TROJAN_PORT=8443

echo ""
echo "✅ Generated Client Links:"
echo "----------------------------------------"

echo "🔗 VLESS:"
echo "vless://$UUID@$SERVER_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"

echo ""
echo "🔗 VMess:"
echo "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"IranAzad\",\"add\":\"$SERVER_IP\",\"port\":\"$VMESS_PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"tcp\",\"type\":\"none\",\"host\":\"\",\"path\":\"\",\"tls\":\"\"}" | base64 -w 0)"

echo ""
echo "🔗 Trojan:"
echo "trojan://$TROJAN_PASS@$SERVER_IP:$TROJAN_PORT#IranAzad"

echo ""
echo "✅ You can use these links in your client apps."
