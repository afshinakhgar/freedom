#!/bin/bash

echo "📡 Setting Iran internal DNS for macOS..."

# Name of the active network service (usually Wi-Fi)
SERVICE_NAME="Wi-Fi"

# Iran DNS servers (Telecom)
IRAN_DNS_1="217.218.155.155"
IRAN_DNS_2="217.218.127.127"

# Set DNS servers
echo "🔧 Applying DNS settings to service: $SERVICE_NAME"
networksetup -setdnsservers "$SERVICE_NAME" $IRAN_DNS_1 $IRAN_DNS_2

# Show current DNS
echo "✅ DNS successfully set:"
networksetup -getdnsservers "$SERVICE_NAME"

