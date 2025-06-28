#!/bin/bash

# Iran Azad Failover & Auto-Recovery Script
# Updated: 2025-06-27

SERVER_IP="8.8.8.8"  # یا IP خارجی معتبر برای تست اینترنت

echo "⏱ Checking connectivity..."

# تست اتصال به اینترنت
if ! ping -c 1 -W 5 $SERVER_IP >/dev/null 2>&1; then
  echo "❌ Internet unreachable! Restarting services..."
  systemctl restart xray-client hysteria-client
  exit 1
fi

# چک سرویس Xray
if ! systemctl is-active --quiet xray-client; then
  echo "❌ Xray client inactive! Restarting..."
  systemctl restart xray-client
else
  echo "✅ Xray client active."
fi

# چک سرویس Hysteria
if ! systemctl is-active --quiet hysteria-client; then
  echo "❌ Hysteria2 client inactive! Restarting..."
  systemctl restart hysteria-client
else
  echo "✅ Hysteria2 client active."
fi

echo "🟢 All checks passed."

