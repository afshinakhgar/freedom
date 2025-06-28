#!/bin/bash

WG_DIR="/etc/wireguard"
WG_INTERFACE="wg0"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"

echo "🔍 Checking WireGuard installation..."
if ! command -v wg > /dev/null; then
  echo "❌ WireGuard is not installed."
  exit 1
else
  echo "✅ WireGuard is installed."
fi

echo "🔐 Checking keys..."
if [[ -f $WG_DIR/privatekey && -f $WG_DIR/publickey ]]; then
  PUBKEY=$(cat $WG_DIR/publickey)
  echo "✅ Keys exist."
  echo "🔑 Public Key: $PUBKEY"
else
  echo "❌ Missing keys in $WG_DIR"
fi

echo "🧾 Checking config file..."
if [[ -f $WG_CONF ]]; then
  echo "✅ Config file exists: $WG_CONF"
else
  echo "❌ Config file not found at $WG_CONF"
fi

echo "📡 Checking service status..."
systemctl is-enabled wg-quick@$WG_INTERFACE &>/dev/null && echo "✅ Service is enabled." || echo "⚠️ Service is not enabled."
systemctl is-active wg-quick@$WG_INTERFACE &>/dev/null && echo "✅ Service is active." || echo "❌ Service is not active."

echo "📊 wg show output:"
wg show $WG_INTERFACE || echo "⚠️ No active interface $WG_INTERFACE"

echo ""
echo "📅 Last handshake:"
wg show $WG_INTERFACE | grep 'latest handshake' || echo "⚠️ No handshake yet."

echo ""
echo "🌐 Current IP & routing:"
ip a show dev $WG_INTERFACE
echo ""
ip route show table main | grep default

echo ""
echo "📶 Testing ping to peer (if AllowedIPs permits)..."
PEER_IP=$(grep Endpoint $WG_CONF | cut -d':' -f1 | awk '{print $3}')
if [[ -n "$PEER_IP" ]]; then
  ping -c 4 "$PEER_IP"
else
  echo "⚠️ Peer IP not found in config."
fi
