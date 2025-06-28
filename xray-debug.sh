#!/bin/bash

set -e

echo "🔎 Starting debugging session..."

# Check if tmux is installed
if ! command -v tmux &>/dev/null; then
  echo "Installing tmux..."
  apt update && apt install -y tmux
fi

SESSION_NAME="xray-debug"

# Kill existing session if exists
tmux kill-session -t $SESSION_NAME 2>/dev/null || true

# Start new tmux session
tmux new-session -d -s $SESSION_NAME

# Pane 1: tail xray access.log
tmux send-keys -t $SESSION_NAME "echo '📄 Tailing /var/log/xray/access.log'; tail -f /var/log/xray/access.log" C-m

# Split window vertically
tmux split-window -v -t $SESSION_NAME

# Pane 2: tcpdump on all interfaces for your VLESS port
read -rp "Enter the VLESS port you want to debug (e.g., 2096): " VLESS_PORT
tmux send-keys -t $SESSION_NAME:0.1 "echo '📡 Capturing traffic on port $VLESS_PORT'; tcpdump -ni any tcp port $VLESS_PORT" C-m

# Attach to session
tmux attach -t $SESSION_NAME
