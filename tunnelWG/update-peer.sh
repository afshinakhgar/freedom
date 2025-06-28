#!/bin/bash

WG_CONF="/etc/wireguard/wg0.conf"
WG_INTERFACE="wg0"
LOG_FILE="/var/log/wg-peer-update.log"

echo "🔐 Enter new PUBLIC key of Iran server:"
read -rp "➡️  New Iran Public Key: " NEW_PUB

echo "🌐 Enter new IP/domain of Iran server (leave blank to keep current):"
read -rp "➡️  New Iran IP (optional): " NEW_IP

# بکاپ
BACKUP="$WG_CONF.bak.$(date +%s)"
cp "$WG_CONF" "$BACKUP"
echo "📦 Backup created: $BACKUP"

# ویرایش PublicKey
OLD_PUB=$(grep -m1 '^PublicKey =' "$WG_CONF" | awk '{print $3}')
sed -i "s|^\(PublicKey = \).*|\1$NEW_PUB|" "$WG_CONF"

# ویرایش Endpoint اگر IP جدید وارد شده باشد
if [[ -n "$NEW_IP" ]]; then
  OLD_IP=$(grep -m1 '^Endpoint =' "$WG_CONF" | cut -d= -f2 | cut -d: -f1 | tr -d ' ')
  sed -i "s|^\(Endpoint = \).*|\1$NEW_IP:51820|" "$WG_CONF"
else
  OLD_IP="(unchanged)"
fi

# ری‌استارت WireGuard
systemctl restart wg-quick@$WG_INTERFACE

# ذخیره لاگ
echo "$(date '+%Y-%m-%d %H:%M:%S') | Updated Iran peer | Old PUB: $OLD_PUB | New PUB: $NEW_PUB | Old IP: $OLD_IP | New IP: ${NEW_IP:-$OLD_IP}" >> "$LOG_FILE"

echo "✅ Peer updated, WireGuard restarted, and log saved to $LOG_FILE!"
echo ""
echo "📊 Current Peer Info:"
wg show $WG_INTERFACE
