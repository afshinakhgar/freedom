#!/bin/bash

echo "📝 Enter OUTSIDE SERVER IP:"
read -rp "Server IP: " SERVER_IP

echo "🔑 Enter UUID (from SERVER):"
read -rp "UUID: " UUID

echo "🔐 Enter Trojan password (from SERVER):"
read -rp "Trojan Password: " TROJAN_PASS

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
