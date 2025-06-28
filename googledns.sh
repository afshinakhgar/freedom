#!/bin/bash

# تشخیص سرویس فعال شبکه (مثل Wi-Fi یا Ethernet)
service=$(networksetup -listallnetworkservices | tail -n +2 | while read svc; do
    if networksetup -getinfo "$svc" | grep -q "IP address"; then
        echo "$svc"
        break
    fi
done)

if [ -z "$service" ]; then
    echo "❌ هیچ سرویس فعالی پیدا نشد."
    exit 1
fi

echo "✅ سرویس فعال پیدا شد: $service"

# تنظیم DNS به Cloudflare (1.1.1.1 و 1.0.0.1)
echo "🛠 در حال تنظیم DNS برای $service ..."
# sudo networksetup -setdnsservers "$service" 1.1.1.1 1.0.0.1
sudo networksetup -setdnsservers "$service" 8.8.8.8 8.8.4.4

# بررسی نتیجه
dns=$(networksetup -getdnsservers "$service")
echo "📡 DNS فعلی برای $service:"
echo "$dns"

# پاک کردن کش DNS
echo "🧹 در حال پاک‌سازی کش DNS ..."
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

echo "🎉 DNS تنظیم شد و کش پاک شد!"

