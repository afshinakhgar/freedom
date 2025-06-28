#!/bin/bash

# ===========================
# WireGuard UDP Connectivity Precheck Script (Interactive)
# Author: IranAzad VPN
# ===========================

WG_INTERFACE="wg0"
WG_PORT=51820

read -rp "🌐 Enter your WireGuard peer IP or domain: " PEER_IP

if [[ -z "$PEER_IP" ]]; then
  echo "❌ No IP/domain provided. Exiting."
  exit 1
fi

echo "🔍 Testing UDP connectivity to $PEER_IP on port $WG_PORT..."

nc -u -v -w 3 $PEER_IP $WG_PORT < /dev/null

if [[ $? -ne 0 ]]; then
  echo "❌ UDP connectivity test failed!"
  echo "⚠️ Either:"
  echo "   - UDP port $WG_PORT is closed on $PEER_IP,"
  echo "   - or your ISP/NAT blocks UDP traffic,"
  echo "   - or there's filtering in the path."
  echo ""
  echo "💡 Try:"
  echo "   - Testing the port from another VPS outside Iran."
  echo "   - Checking server's firewall rules."
else
  echo "✅ UDP connectivity to $PEER_IP:$WG_PORT successful!"
fi

echo ""
echo "🚀 If UDP works, you can start WireGuard with:"
echo "    systemctl restart wg-quick@$WG_INTERFACE"

