#!/bin/bash

# ===============================================
# Iran Azad OpenVPN NAT & Forwarding Setup
# Must run on Outside (Server) Node
# ===============================================

# 1️⃣ فعال کردن IP forwarding
echo "🔧 Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
sysctl --system

# 2️⃣ اضافه کردن NAT روی رابط خروجی
# رابط اصلی رو پیدا می‌کنیم:
IF_EXT=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

echo "🔧 Setting up NAT on $IF_EXT..."
iptables -t nat -A POSTROUTING -s 10.88.0.0/24 -o $IF_EXT -j MASQUERADE

# 3️⃣ ذخیره iptables در سیستم
apt install -y iptables-persistent
netfilter-persistent save

echo "✅ NAT & forwarding configured. Server ready for tunnel traffic!"
