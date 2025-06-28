#!/bin/bash

set -e

# نصب jq اگر نباشه
apt update && apt install -y jq

# دریافت IP سرور خارج
read -rp "📝 Enter OUTSIDE SERVER IP: " SERVER_IP
echo "Server IP: $SERVER_IP"

CONFIG="/opt/xray/config.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Config file not found at $CONFIG"
  exit 1
fi

echo "🔎 Found config file: $CONFIG"

# خواندن UUID از بخش outbounds > vless
UUID=$(jq -r '.outbounds[] | select(.protocol=="vless") | .settings.vnext[0].users[0].id' "$CONFIG")

# خواندن پسورد Trojan از بخش outbounds > trojan
TROJAN_PASS=$(jq -r '.outbounds[] | select(.protocol=="trojan") | .settings.servers[0].password' "$CONFIG")

echo ""
echo "✅ Here are your clients:"
echo "Your UUID: $UUID"
echo "Your Trojan Password: $TROJAN_PASS"
echo "----------------------------------------"
echo "🔗 VLESS:"
echo "vless://$UUID@$SERVER_IP:2096?encryption=none&security=none&type=tcp#IranAzad"
echo ""

VMESS_JSON=$(cat <<EOF
{"v":"2","ps":"IranAzad","add":"$SERVER_IP","port":"2087","id":"$UUID","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
EOF
)
echo "🔗 VMess:"
echo "vmess://$(echo "$VMESS_JSON" | base64 -w 0)"
echo ""

echo "🔗 Trojan:"
echo "trojan://$TROJAN_PASS@$SERVER_IP:8443#IranAzad"
echo ""
echo "✅ You can use these links in your client apps."
