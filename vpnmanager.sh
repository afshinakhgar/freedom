#!/bin/bash

WG_SERVICE="wg-quick@wg0"
OVPN_SERVICE="openvpn@client"

install_wireguard() {
    echo "🔧 Installing WireGuard..."
    apt update && apt install -y wireguard
    echo "✅ WireGuard installed."
}

install_openvpn() {
    echo "🔧 Installing OpenVPN..."
    apt update && apt install -y openvpn easy-rsa
    echo "✅ OpenVPN installed."
}

start_wireguard() {
    echo "🚀 Starting WireGuard..."
    systemctl start $WG_SERVICE
}

stop_wireguard() {
    echo "🛑 Stopping WireGuard..."
    systemctl stop $WG_SERVICE
}

start_openvpn() {
    echo "🚀 Starting OpenVPN..."
    systemctl start $OVPN_SERVICE
}

stop_openvpn() {
    echo "🛑 Stopping OpenVPN..."
    systemctl stop $OVPN_SERVICE
}

setup_failover_wireguard() {
    echo "🔄 Setting up WireGuard failover..."
    cp ./failover-switch.sh /usr/local/bin/failover-switch.sh
    chmod +x /usr/local/bin/failover-switch.sh
    (crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/failover-switch.sh") | crontab -
    echo "✅ WireGuard failover configured."
}

setup_failover_openvpn() {
    echo "🔄 Setting up OpenVPN failover..."
    cp ./failover-openvpn.sh /usr/local/bin/failover-openvpn.sh
    chmod +x /usr/local/bin/failover-openvpn.sh
    (crontab -l 2>/dev/null; echo "*/1 * * * * /usr/local/bin/failover-openvpn.sh") | crontab -
    echo "✅ OpenVPN failover configured."
}

status() {
    echo "📊 Service statuses:"
    systemctl status $WG_SERVICE --no-pager || true
    systemctl status $OVPN_SERVICE --no-pager || true
}

case "$1" in
  install-wireguard) install_wireguard ;;
  install-openvpn) install_openvpn ;;
  start-wireguard) start_wireguard ;;
  stop-wireguard) stop_wireguard ;;
  start-openvpn) start_openvpn ;;
  stop-openvpn) stop_openvpn ;;
  setup-failover-wireguard) setup_failover_wireguard ;;
  setup-failover-openvpn) setup_failover_openvpn ;;
  status) status ;;
  *)
    echo "Usage: $0 {install-wireguard|install-openvpn|start-wireguard|stop-wireguard|start-openvpn|stop-openvpn|setup-failover-wireguard|setup-failover-openvpn|status}"
    exit 1
    ;;
esac

