#!/bin/bash

# Iran Azad Unified Status Checker
# Updated: 2025-06-27

echo "🔍 Checking Xray..."
if systemctl is-active --quiet xray || systemctl is-active --quiet xray-client; then
  echo "✅ Xray is active."
else
  echo "❌ Xray is not running!"
fi

echo "📄 Xray log (last 10 lines):"
journalctl -u xray -u xray-client -n 10 --no-pager 2>/dev/null || echo "(no logs found)"

echo ""
echo "🔍 Checking Hysteria2..."
if systemctl is-active --quiet hysteria || systemctl is-active --quiet hysteria-client; then
  echo "✅ Hysteria2 is active."
else
  echo "❌ Hysteria2 is not running!"
fi

echo "📄 Hysteria2 log (last 10 lines):"
journalctl -u hysteria -u hysteria-client -n 10 --no-pager 2>/dev/null || echo "(no logs found)"

echo ""
echo "📊 Testing outbound connectivity..."
curl -s --max-time 5 https://api.ipify.org && echo " ✅ Internet is reachable." || echo "❌ Internet is unreachable!"

echo ""
echo "📡 Checking open ports:"
ss -lnupt | grep -E '(:443|:8443)' || echo "(no relevant open ports found)"

echo ""
echo "📶 Checking if SOCKS proxies are up:"
lsof -i :1080 -i :1081 2>/dev/null | grep LISTEN || echo "(no SOCKS proxies listening on 1080/1081)"

echo ""
echo "📝 Done."
