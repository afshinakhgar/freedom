#!/bin/bash

echo "🚫 Stopping potential conflicting services..."

# Stop WireGuard
if systemctl is-active --quiet wg-quick@wg0; then
  echo "🔹 Stopping WireGuard (wg-quick@wg0)..."
  systemctl stop wg-quick@wg0
  systemctl disable wg-quick@wg0
else
  echo "✅ WireGuard is not running."
fi

# Stop Xray (if old instance is running)
if systemctl is-active --quiet xray; then
  echo "🔹 Stopping old Xray service..."
  systemctl stop xray
  systemctl disable xray
else
  echo "✅ Xray is not running."
fi

# Optional: stop other VPNs / proxies you know are installed (OpenVPN, etc.)
# Example for OpenVPN
if systemctl list-units --full -all | grep -q "openvpn"; then
  echo "🔹 Stopping OpenVPN services..."
  systemctl stop openvpn*
  systemctl disable openvpn*
else
  echo "✅ OpenVPN is not running."
fi

echo ""
echo "🚀 All conflicting services stopped and disabled (if any)."
echo "✅ Ready to start Xray cleanly."
