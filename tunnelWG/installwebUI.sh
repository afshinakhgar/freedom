#!/bin/bash

# =================================================
# IranAzad VPN - Standalone Web UI Installer (PHP)
# Author: Afshin Akhgar
# Date: 2025-06-26
# Description: Install lightweight Web UI to manage users
# =================================================

WEBUI_DIR="/opt/iranazad-webui"
CONFIG_PATH="/opt/xray/config.json"

# --- Install dependencies ---
echo "📦 Installing dependencies: PHP + Lighttpd"
apt update && apt install -y php php-cli php-sqlite3 lighttpd

# --- Create UI directory ---
echo "📁 Creating Web UI directory at $WEBUI_DIR"
mkdir -p "$WEBUI_DIR"

# --- Create index.php ---
echo "📝 Creating Web UI PHP script"
cat > "$WEBUI_DIR/index.php" <<'PHP'
<?php
\$configPath = "/opt/xray/config.json";
header("Content-Type: application/json");

switch (\$_SERVER['REQUEST_METHOD']) {
    case 'GET':
        \$json = file_get_contents(\$configPath);
        \$data = json_decode(\$json, true);
        \$clients = [];
        foreach (\$data['inbounds'] as \$inbound) {
            if (in_array(\$inbound['protocol'], ['vless', 'vmess', 'trojan'])) {
                if (isset(\$inbound['settings']['clients'])) {
                    foreach (\$inbound['settings']['clients'] as \$client) {
                        \$client['protocol'] = \$inbound['protocol'];
                        \$clients[] = \$client;
                    }
                }
            }
        }
        echo json_encode(\$clients, JSON_PRETTY_PRINT);
        break;

    case 'POST':
        \$input = json_decode(file_get_contents("php://input"), true);
        if (!isset(\$input['protocol'], \$input['client'])) {
            http_response_code(400);
            echo json_encode(["error" => "Missing protocol or client data"]);
            break;
        }

        \$json = file_get_contents(\$configPath);
        \$data = json_decode(\$json, true);
        \$updated = false;

        foreach (\$data['inbounds'] as &\$inbound) {
            if (\$inbound['protocol'] === \$input['protocol']) {
                \$inbound['settings']['clients'][] = \$input['client'];
                \$updated = true;
                break;
            }
        }

        if (\$updated) {
            file_put_contents(\$configPath, json_encode(\$data, JSON_PRETTY_PRINT));
            exec("systemctl restart xray");
            echo json_encode(["status" => "ok"]);
        } else {
            http_response_code(404);
            echo json_encode(["error" => "Protocol not found"]);
        }
        break;

    default:
        http_response_code(405);
        echo json_encode(["error" => "Method Not Allowed"]);
}
PHP

# --- Configure Lighttpd ---
echo "⚙️ Configuring Lighttpd"
cat > /etc/lighttpd/conf-available/99-iranazad-webui.conf <<EOF
server.document-root = "$WEBUI_DIR"
server.port = 8080
index-file.names = ("index.php")
server.modules += ("mod_fastcgi", "mod_accesslog")
fastcgi.server = (
  ".php" => ((
    "bin-path" => "/usr/bin/php-cgi",
    "socket" => "/tmp/php.socket"
  ))
)
EOF

ln -sf /etc/lighttpd/conf-available/99-iranazad-webui.conf /etc/lighttpd/conf-enabled/
systemctl enable lighttpd
systemctl restart lighttpd

# --- Completion message ---
echo "\n✅ Web UI installed successfully!"
echo "🌐 Access it via: http://<your_server_ip>:8080"
