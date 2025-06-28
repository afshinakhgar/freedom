#!/bin/bash

set -e

if ! command -v jq &>/dev/null; then
  apt update && apt install -y jq
fi

read -rp "📝 Enter SERVER IP: " SERVER_IP

CONFIG="/opt/xray/config.json"
if [[ ! -f "$CONFIG" ]]; then
  echo "❌ Config file not found at $CONFIG"
  exit 1
fi

echo "🔎 Reading config from $CONFIG..."

UUID=$(jq -r '.inbounds[0].settings.clients[0].id' $CONFIG)
TROJAN_PASS=$(jq -r '.inbounds[2].settings.clients[0].password // .inbounds[2].settings.clients[0].password' $CONFIG)
VLESS_PORT=$(jq -r '.inbounds[0].port' $CONFIG)
VMESS_PORT=$(jq -r '.inbounds[1].port' $CONFIG)
TROJAN_PORT=$(jq -r '.inbounds[2].port' $CONFIG)

if [[ -z "$UUID" || "$UUID" == "null" ]]; then
  echo "❌ Could not find UUID in config."
  exit 1
fi

if [[ -z "$TROJAN_PASS" || "$TROJAN_PASS" == "null" ]]; then
  echo "❌ Could not find Trojan password in config."
  exit 1
fi

echo ""
echo "✅ Your clients:"
echo "UUID: $UUID"
echo "Trojan Password: $TROJAN_PASS"
echo ""
echo "🔗 VLESS:"
echo "vless://$UUID@$SERVER_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"
echo ""
echo "🔗 VMess:"
VMESS_JSON=$(cat <<EOF
{"v":"2","ps":"IranAzad","add":"$SERVER_IP","port":"$VMESS_PORT","id":"$UUID","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
EOF
)
echo "vmess://$(echo -n "$VMESS_JSON" | base64 -w 0)"
echo ""
echo "🔗 Trojan:"
echo "trojan://$TROJAN_PASS@$SERVER_IP:$TROJAN_PORT#IranAzad"
