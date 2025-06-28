#!/bin/bash

# مشخصات فایل‌ها و تنظیمات
WG_CONF="/etc/wireguard/wg0.conf"
WG_INTERFACE="wg0"
WG_IP_IR="10.66.66.2"

echo "🔐 Enter new PUBLIC key of Iran node:"
read -rp "➡️  New Iran Public Key: " NEW_PUB

# پشتیبان‌گیری از فایل قبلی
cp "$WG_CONF" "$WG_CONF.bak.$(date +%s)"
echo "📦 Backup created: $WG_CONF.bak.$(date +%s)"

# ویرایش فایل کانفیگ (Peer section)
echo "✍️ Updating config file..."
sed -i "/^\[Peer\]/,/^$/ s|^PublicKey = .*|PublicKey = $NEW_PUB|" "$WG_CONF"

# اعمال تغییرات
echo "🔄 Restarting WireGuard..."
systemctl restart wg-quick@$WG_INTERFACE

# نمایش وضعیت
echo "✅ Done. New configuration loaded."
echo ""
echo "📡 Current Peer Info:"
wg show $WG_INTERFACE | grep -A 10 "$NEW_PUB"
