#!/bin/bash

echo "🔄 Resetting DNS to automatic (via DHCP)..."

SERVICE_NAME="Wi-Fi"
networksetup -setdnsservers "$SERVICE_NAME" "Empty"

echo "✅ DNS reset complete:"
networksetup -getdnsservers "$SERVICE_NAME"

