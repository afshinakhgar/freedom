#!/bin/bash

# Iran Azad Server Monitor Script
# Updated: 2025-06-27

echo "⏱ Checking Xray Server..."

if ! systemctl is-active --quiet xray; then
  echo "❌ Xray server inactive! Restarting..."
  systemctl restart xray
else
  echo "✅ Xray server active."
fi

echo ""
echo "⏱ Checking Hysteria2 Server..."

if ! systemctl is-active --quiet hysteria; then
  echo "❌ Hysteria2 server inactive! Restarting..."
  systemctl restart hysteria
else
  echo "✅ Hysteria2 server active."
fi

echo ""
echo "📊 Testing inbound ports..."

# بررسی باز بودن پورت های حیاتی
ss -lnup | grep -E '(:443|:8443)' || echo "⚠️  Important ports not found in listening state!"

echo "🟢 Server monitor checks completed."

