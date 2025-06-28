#!/bin/bash

set -e

apt update && apt install -y jq

XRAY_CONFIG="/opt/xray/config.json"

read -rp "📝 Enter OUTSIDE SERVER IP: " SERVER_IP
# Trim invalid or non-printable characters and spaces
SERVER_IP=$(echo "$SERVER_IP" | tr -cd '[:print:]' | sed 's/^[ \t]*//;s/[ \t]*$//')
echo "🔎 Using Server IP: $SERVER_IP"

if [[ ! -f "$XRAY_CONFIG" ]]; then
  echo "❌ Config file not found at $XRAY_CONFIG"
  exit 1
fi

echo "🔎 Found config file: $XRAY_CONFIG"

# Extract UUID from vless outbound
UUID=$(jq -r '.outbounds[] | select(.protocol=="vless") | .settings.vnext[0].users[0].id' "$XRAY_CONFIG")

# Extract Trojan password
TROJAN_PASS=$(jq -r '.outbounds[] | select(.protocol=="trojan") | .settings.servers[0].password' "$XRAY_CONFIG")

echo ""
echo "✅ Here are your clients:"
echo "Your UUID: $UUID"
echo "Your Trojan Password: $TROJAN_PASS"
echo ""

echo "🔗 VLESS:"
echo "vless://$UUID@$SERVER_IP:2096?encryption=none&security=none&type=tcp#IranAzad"

echo ""
echo "🔗 VMess:"
VMESS_JSON=$(cat <<EOF
{"v":"2","ps":"IranAzad","add":"$SERVER_IP","port":"2087","id":"$UUID","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
EOF
)
echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"

echo ""
echo "🔗 Trojan:"
echo "trojan://$TROJAN_PASS@$SERVER_IP:8443#IranAzad"

echo ""
echo "✅ You can use these links in your client apps."
