#!/bin/bash

# تنظیمات
PRIMARY_IP="91.132.92.213"
BACKUP_IP="185.123.45.67"
WG_CONF="/etc/wireguard/wg0.conf"
WG_SERVICE="wg-quick@wg0"
MAX_FAILS=3
FAIL_COUNT_FILE="/tmp/wg_fail_count"

# توکن و chat_id تلگرام
TG_TOKEN="123456789:ABCDEF-TOKEN"
TG_CHAT_ID="987654321"

# تابع ارسال پیام به تلگرام
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
    if ! grep -q "$PRIMARY_IP" "$WG_CONF"; then
        sed -i "s/Endpoint.*/Endpoint = $PRIMARY_IP:51820/" $WG_CONF
        systemctl restart $WG_SERVICE
        send_telegram "✅ *Switched back to PRIMARY* ($PRIMARY_IP)"
        echo "🔄 Switched back to PRIMARY ($PRIMARY_IP)"
    fi
else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    echo $FAIL_COUNT > $FAIL_COUNT_FILE

    if [[ $FAIL_COUNT -ge $MAX_FAILS ]]; then
        if ! grep -q "$BACKUP_IP" "$WG_CONF"; then
            sed -i "s/Endpoint.*/Endpoint = $BACKUP_IP:51820/" $WG_CONF
            systemctl restart $WG_SERVICE
            send_telegram "⚠️ *Switched to BACKUP* ($BACKUP_IP) due to failures."
            echo "⚠️ Switched to BACKUP ($BACKUP_IP) due to failures."
        fi
    fi
fi

