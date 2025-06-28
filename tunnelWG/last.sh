#!/bin/bash

WG_DIR="/etc/wireguard"
WG_INTERFACE="wg0"
WG_NET="10.66.66.0/24"
WG_IP_IR="10.66.66.2"
WG_CONF="$WG_DIR/$WG_INTERFACE.conf"
IF_EXT="$(ip route get 1 | awk '{print $5; exit}')"

mkdir -p $WG_DIR
apt update && apt install -y wireguard resolvconf

umask 077
cd $WG_DIR || exit 1
[[ ! -f privatekey ]] && wg genkey | tee privatekey | wg pubkey > publickey
PRIVKEY=$(cat privatekey)
PUBKEY=$(cat publickey)

echo "🔐 Your public key: $PUBKEY"
read -rp "Enter public key of FOREIGN server: " PEER_PUB
read -rp "Enter IP/domain of FOREIGN server: " PEER_IP

echo "🌐 Testing UDP ports..."
PORTS=(53 123 443 1194 51820)
FOUND_PORT=""
for PORT in "${PORTS[@]}"; do
  echo -n "Checking UDP port $PORT... "
  nc -zvu -w2 $PEER_IP $PORT >/dev/null 2>&1
  if [[ $? -eq 0 ]]; then
    echo "✅ Open!"
    FOUND_PORT=$PORT
    break
  else
    echo "❌ Closed."
  fi
done

if [[ -z "$FOUND_PORT" ]]; then
  echo "❌ No open UDP port found. Exiting."
  exit 1
else
  WG_PORT=$FOUND_PORT
  echo "✅ Using UDP port $WG_PORT for WireGuard"
fi

cat > $WG_CONF <<EOF
[Interface]
PrivateKey = $PRIVKEY
Address = $WG_IP_IR/24
DNS = 1.1.1.1
ListenPort = $WG_PORT

[Peer]
PublicKey = $PEER_PUB
Endpoint = $PEER_IP:$WG_PORT
AllowedIPs = 8.8.8.8/32
PersistentKeepalive = 25
EOF

systemctl enable wg-quick@$WG_INTERFACE
systemctl restart wg-quick@$WG_INTERFACE

echo "🔧 Setting up failover check script..."
cat > /usr/local/bin/failover-check.sh <<'EOF'
#!/bin/bash
WG_INTERFACE="wg0"
WG_CONF="/etc/wireguard/${WG_INTERFACE}.conf"

LAST_HANDSHAKE=$(wg show $WG_INTERFACE latest-handshakes | awk '{print $2}')
NOW=$(date +%s)

if [[ -z "$LAST_HANDSHAKE" || "$LAST_HANDSHAKE" -eq 0 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | No handshake info. Skipping."
  exit 0
fi

DIFF=$((NOW - LAST_HANDSHAKE))

if [[ $DIFF -le 30 ]]; then
  if grep -q "AllowedIPs = 8.8.8.8/32" "$WG_CONF"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') | Handshake OK. Updating AllowedIPs to full tunnel."
    sed -i "s|AllowedIPs = .*|AllowedIPs = 0.0.0.0/1, 128.0.0.0/1|" "$WG_CONF"
    wg syncconf $WG_INTERFACE <(wg-quick strip $WG_INTERFACE)
  fi
  exit 0
fi

if [[ $DIFF -gt 60 ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | No handshake for $DIFF sec. Bringing down $WG_INTERFACE."
  wg-quick down $WG_INTERFACE
fi
EOF

chmod +x /usr/local/bin/failover-check.sh
(crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/failover-check.sh") | crontab -

echo "✅ WireGuard setup completed with failover mechanism!"
