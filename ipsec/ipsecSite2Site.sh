#!/bin/bash

# ===============================================
# Iran Azad IPsec Site-to-Site Installer (with Health Check)
# Supports: IPsec (strongSwan) between Iran <-> Outside
# For: Ubuntu 22.04+
# Updated: 2025-06-27
# ===============================================

IPSEC_CONF="/etc/ipsec.conf"
IPSEC_SECRETS="/etc/ipsec.secrets"
PSK="MySuperSecurePsk123456"

echo "🔧 Server role:"
echo "1) 🇮🇷 Iran (Client Node)"
echo "2) 🌍 Outside (Gateway Node)"
read -rp "Choose 1 or 2: " ROLE

echo "🔨 Installing strongSwan..."
apt update && apt install -y strongswan

if [[ "$ROLE" == "1" ]]; then
  read -rp "Enter PUBLIC IP of Iran server: " LOCAL_IP
  read -rp "Enter PUBLIC IP of FOREIGN server: " REMOTE_IP

  cat > $IPSEC_CONF <<EOF
config setup
  charondebug="ike 2, knl 2, cfg 2, net 2"

conn iran-to-foreign
  auto=start
  keyexchange=ikev2
  type=tunnel
  left=$LOCAL_IP
  leftid=$LOCAL_IP
  leftsubnet=0.0.0.0/0
  right=$REMOTE_IP
  rightid=$REMOTE_IP
  rightsubnet=0.0.0.0/0
  ike=aes256-sha256-modp2048
  esp=aes256-sha256
  keyingtries=%forever
  ikelifetime=60m
  lifetime=20m
  dpdaction=restart
EOF

  cat > $IPSEC_SECRETS <<EOF
$LOCAL_IP $REMOTE_IP : PSK "$PSK"
EOF

elif [[ "$ROLE" == "2" ]]; then
  read -rp "Enter PUBLIC IP of FOREIGN server: " LOCAL_IP
  read -rp "Enter PUBLIC IP of Iran server: " REMOTE_IP

  cat > $IPSEC_CONF <<EOF
config setup
  charondebug="ike 2, knl 2, cfg 2, net 2"

conn foreign-to-iran
  auto=start
  keyexchange=ikev2
  type=tunnel
  left=$LOCAL_IP
  leftid=$LOCAL_IP
  leftsubnet=0.0.0.0/0
  right=$REMOTE_IP
  rightid=$REMOTE_IP
  rightsubnet=0.0.0.0/0
  ike=aes256-sha256-modp2048
  esp=aes256-sha256
  keyingtries=%forever
  ikelifetime=60m
  lifetime=20m
  dpdaction=restart
EOF

  cat > $IPSEC_SECRETS <<EOF
$LOCAL_IP $REMOTE_IP : PSK "$PSK"
EOF

else
  echo "❌ Invalid role."
  exit 1
fi

echo "🔄 Restarting strongSwan..."
systemctl restart strongswan

echo ""
echo "✅ IPsec configuration complete!"
echo "📊 Current IPsec status:"
ipsec statusall

# 🔧 ایجاد اسکریپت health-check
echo "🔧 Setting up IPsec health-check script at /usr/local/bin/ipsec-health.sh..."
cat > /usr/local/bin/ipsec-health.sh <<'EOF'
#!/bin/bash
STATUS=$(ipsec status | grep -i established)
if [[ -n "$STATUS" ]]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Tunnel OK: $STATUS"
else
  echo "$(date '+%Y-%m-%d %H:%M:%S') | Tunnel DOWN! Attempting restart..."
  systemctl restart strongswan
fi
EOF

chmod +x /usr/local/bin/ipsec-health.sh

# پیشنهاد کران‌جاب
echo ""
echo "📝 To automatically check the tunnel every minute, add this to your crontab:"
echo "*/1 * * * * /usr/local/bin/ipsec-health.sh >> /var/log/ipsec-health.log 2>&1"
