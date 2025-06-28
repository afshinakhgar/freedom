#!/bin/bash

set -e

apt update && apt install -y jq

read -rp "📝 Enter OUTSIDE SERVER IP: " SERVER_IP
echo "Server IP: $SERVER_IP"

CONFIG_FILE="/opt/xray/config.json"

if [[ ! -f "$CONFIG_FILE" ]]; then
  echo "❌ Config file not found: $CONFIG_FILE"
  exit 1
fi

echo "🔎 Found config file: $CONFIG_FILE"

UUID=$(jq -r '.outbounds[] | select(.protocol=="vless") | .settings.vnext[0].users[0].id' "$CONFIG_FILE")
TROJAN_PASS=$(jq -r '.outbounds[] | select(.protocol=="trojan") | .settings.servers[0].password' "$CONFIG_FILE")

if [[ -z "$UUID" || "$UUID" == "null" ]]; then
  echo "❌ Failed to read UUID from config!"
  exit 1
fi

if [[ -z "$TROJAN_PASS" || "$TROJAN_PASS" == "null" ]]; then
  echo "❌ Failed to read Trojan password from config!"
  exit 1
fi

echo ""
echo "✅ Here are your clients:"
echo "Your UUID: $UUID"
echo "Your Trojan Password: $TROJAN_PASS"
echo ""
echo "vless://$UUID@$SERVER_IP:2096?encryption=none&security=none&type=tcp#IranAzad"
echo ""
VMESS_JSON=$(jq -n --arg v "2" --arg ps "IranAzad" --arg add "$SERVER_IP" --arg port "2087" --arg id "$UUID" --arg aid "0" --arg net "tcp" '{"v":$v,"ps":$ps,"add":$add,"port":$port,"id":$id,"aid":$aid,"net":$net,"type":"none","host":"","path":"","tls":""}')
echo "vmess://$(echo "$VMESS_JSON" | base64 -w 0)"
echo ""
echo "trojan://$TROJAN_PASS@$SERVER_IP:8443#IranAzad"
echo ""
echo "✅ You can use these links in your client apps."
