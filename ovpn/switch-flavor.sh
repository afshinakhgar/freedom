#!/bin/bash

# تنظیمات
PRIMARY_IP="91.132.92.213"
BACKUP_IP="185.123.45.67"
OVPN_CONF="/etc/openvpn/client.conf"
OVPN_SERVICE="openvpn@client"
MAX_FAILS=3
FAIL_COUNT_FILE="/tmp/openvpn_fail_count"

# توکن و chat_id تلگرام
TG_TOKEN="123456789:ABCDEF-TOKEN"
TG_CHAT_ID="987654321"

send_telegram() {
    local MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="$MESSAGE" \
        -d parse_mode="Markdown"
}

# مقدار شمارنده فعلی
FAIL_COUNT=$(cat $FAIL_COUNT_FILE 2>/dev/null || echo 0)

# تست ارتباط با سرور اصلی
if ping -c 2 $PRIMARY_IP >/dev/null 2>&1; then
    echo 0 > $FAIL_COUNT_FILE
    if ! grep -q "$PRIMARY_IP" "$OVPN_CONF"; then
        sed -i "s/^remote .*/remote $PRIMARY_IP 443/" $OVPN_CONF
        systemctl restart $OVPN_SERVICE
        send_telegram "✅ *OpenVPN: Switched back to PRIMARY* ($PRIMARY_IP)"
        echo "🔄 OpenVPN switched back to PRIMARY ($PRIMARY_IP)"
    fi
else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo $FAIL_COUNT > $FAIL_COUNT_FILE

    if [[ $FAIL_COUNT -ge $MAX_FAILS ]]; then
        if ! grep -q "$BACKUP_IP" "$OVPN_CONF"; then
            sed -i "s/^remote .*/remote $BACKUP_IP 443/" $OVPN_CONF
            systemctl restart $OVPN_SERVICE
            send_telegram "⚠️ *OpenVPN: Switched to BACKUP* ($BACKUP_IP) due to failures."
            echo "⚠️ OpenVPN switched to BACKUP ($BACKUP_IP) due to failures."
        fi
    fi
fi
