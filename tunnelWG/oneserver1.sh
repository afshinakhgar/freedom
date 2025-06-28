#!/bin/bash

echo "==== VPN Installer (No TLS / No Domain) ===="

read -p "Enter your public server IP (e.g., 1.2.3.4): " SERVER_IP

# Install required packages
apt update && apt install -y curl unzip wget git socat

# Install Xray Core
XRAY_VERSION=$(curl -s "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep tag_name | cut -d '"' -f 4)
mkdir -p /usr/local/bin/xray
cd /usr/local/bin/xray || exit
wget https://github.com/XTLS/Xray-core/releases/download/${XRAY_VERSION}/Xray-linux-64.zip
unzip Xray-linux-64.zip
chmod +x xray
rm -f Xray-linux-64.zip

# Create required directories and files
mkdir -p /etc/xray /var/log/xray
touch /etc/xray/config.json

# Generate UUID
UUID=$(cat /proc/sys/kernel/random/uuid)

# Write Xray config with VMess, VLESS, Trojan, and Shadowsocks (no TLS)
cat <<EOF > /etc/xray/config.json
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [
    {
      "port": 10001,
      "protocol": "vmess",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vmess"
        }
      }
    },
    {
      "port": 10002,
      "protocol": "vless",
      "settings": {
        "clients": [
          { "id": "$UUID" }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vless"
        }
      }
    },
    {
      "port": 10003,
      "protocol": "trojan",
      "settings": {
        "clients": [
          { "password": "$UUID" }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "port": 10004,
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "$UUID",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ]
}
EOF

# Create systemd service for Xray
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=/usr/local/bin/xray/xray -config /etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Start and enable Xray service
systemctl daemon-reexec
systemctl enable xray
systemctl restart xray

# Display connection information
echo -e "\n✅ Installation complete!"
echo -e "\n🔑 UUID: $UUID"
echo -e "\n🌐 Connection links:"
echo "➡️  VMess (no TLS): vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"vmess\",\"add\":\"$SERVER_IP\",\"port\":\"10001\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"type\":\"none\",\"host\":\"\",\"path\":\"/vmess\",\"tls\":\"\"}" | base64 -w 0)"
echo "➡️  VLESS (no TLS): vless://$UUID@$SERVER_IP:10002?encryption=none&security=none&type=ws&path=%2Fvless#vless"
echo "➡️  Trojan (no TLS): trojan://$UUID@$SERVER_IP:10003"
echo "➡️  Shadowsocks: ss://$(echo -n "chacha20-ietf-poly1305:$UUID" | base64 -w 0)@$SERVER_IP:10004#ss"

echo -e "\n🚀 Now you can import these links into your VPN clients and start using your server."
