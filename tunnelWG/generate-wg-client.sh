#!/bin/bash

# ==========================
# IranAzad Xray Client Links Generator
# Outputs final links for VLESS / VMess / Shadowsocks / Trojan.
# ==========================

XRAY_DIR="/opt/xray"
VLESS_PORT=2096
VMESS_PORT=2087
SHADOW_PORT=8388
TROJAN_PORT=8443

# 🔎 خواندن UUIDها و پسوردها از config اصلی یا از ورودی
if [[ -f "$XRAY_DIR/config.json" ]]; then
  UUID=$(grep -oP '"id"\s*:\s*"\K[^"]+' $XRAY_DIR/config.json | head -n 1)
  VMESS_UUID=$(grep -oP '"id"\s*:\s*"\K[^"]+' $XRAY_DIR/config.json | tail -n 1)
  SHADOW_PASS=$(grep -oP '"password"\s*:\s*"\K[^"]+' $XRAY_DIR/config.json | head -n 1)
  TROJAN_PASS=$(grep -oP '"password"\s*:\s*"\K[^"]+' $XRAY_DIR/config.json | tail -n 1)
else
  read -rp "Enter VLESS UUID: " UUID
  read -rp "Enter VMess UUID: " VMESS_UUID
  read -rp "Enter Shadowsocks Password: " SHADOW_PASS
  read -rp "Enter Trojan Password: " TROJAN_PASS
fi

SERVER_REAL_IP=$(curl -s https://api.ipify.org || hostname -I | cut -d" " -f1)

echo ""
echo "✅ Generated Links:"
echo ""
echo "🔹 VLESS:"
echo "vless://$UUID@$SERVER_REAL_IP:$VLESS_PORT?encryption=none&security=none&type=tcp#IranAzad"
echo ""
echo "🔹 VMess:"
VMESS_JSON=$(cat <<EOF
{"v":"2","ps":"IranAzad","add":"$SERVER_REAL_IP","port":"$VMESS_PORT","id":"$VMESS_UUID","aid":"0","net":"tcp","type":"none","host":"","path":"","tls":""}
EOF
)
echo "vmess://$(echo "$VMESS_JSON" | base64 -w 0)"
echo ""
echo "🔹 Shadowsocks:"
echo "ss://$(echo -n "aes-128-gcm:$SHADOW_PASS@$SERVER_REAL_IP:$SHADOW_PORT" | base64 -w 0)#IranAzad"
echo ""
echo "🔹 Trojan:"
echo "trojan://$TROJAN_PASS@$SERVER_REAL_IP:$TROJAN_PORT#IranAzad"
echo ""
