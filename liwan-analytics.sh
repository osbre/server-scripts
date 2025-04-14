#!/bin/bash

set -euo pipefail

# --- Parse args ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --email)
            EMAIL="$2"
            shift 2
            ;;
        --maxmind-id)
            MAXMIND_ID="$2"
            shift 2
            ;;
        --maxmind-key)
            MAXMIND_KEY="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
    esac
done

# --- Validate required params ---
if [[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" ]]; then
    echo "❌ Usage: $0 --domain your.domain.com --email you@example.com [--maxmind-id ID --maxmind-key KEY]"
    exit 1
fi

# --- Setup variables ---
USERNAME="liwan"
INSTALL_DIR="/home/$USERNAME/.local/bin"
CONFIG_DIR="/home/$USERNAME/.config/liwan"
SERVICE_FILE="/etc/systemd/system/liwan.service"
BIN_URL="https://github.com/explodingcamera/liwan/releases/latest/download/liwan-x86_64-unknown-linux-musl.tar.gz"

# --- Create user ---
if ! id -u "$USERNAME" >/dev/null 2>&1; then
    useradd --create-home --shell /usr/sbin/nologin "$USERNAME"
fi

# --- Install binary ---
mkdir -p "$INSTALL_DIR"
curl -sSL "$BIN_URL" -o /tmp/liwan.tar.gz
tar -xzf /tmp/liwan.tar.gz -C "$INSTALL_DIR" liwan
chmod +x "$INSTALL_DIR/liwan"
chown -R "$USERNAME:$USERNAME" "$INSTALL_DIR"
rm /tmp/liwan.tar.gz

# --- Generate config ---
mkdir -p "$CONFIG_DIR"
cat > "$CONFIG_DIR/liwan.config.toml" <<EOF
base_url = "https://$DOMAIN"
port = 9042
data_dir = "/home/$USERNAME/.local/share/liwan/data"
EOF

# Append GeoIP section if credentials provided
if [[ -n "${MAXMIND_ID:-}" && -n "${MAXMIND_KEY:-}" ]]; then
cat >> "$CONFIG_DIR/liwan.config.toml" <<EOF

[geoip]
maxmind_account_id = "$MAXMIND_ID"
maxmind_license_key = "$MAXMIND_KEY"
maxmind_edition = "GeoLite2-City"
EOF
fi

chown -R "$USERNAME:$USERNAME" "$CONFIG_DIR"

# --- Caddy setup ---
CADDYFILE="/etc/caddy/Caddyfile"
touch "$CADDYFILE"

# Add email block if missing
if ! grep -q "^\s*email\s" "$CADDYFILE"; then
    sed -i "1i\\
{\\
    email $EMAIL\\
}" "$CADDYFILE"
fi

# Replace domain block
sed -i "/^$DOMAIN {/,/^}/d" "$CADDYFILE"
cat >> "$CADDYFILE" <<EOF

$DOMAIN {
    reverse_proxy 127.0.0.1:9042
}
EOF

[ -d /etc/caddy ] && chown -R caddy:caddy /etc/caddy/
[ -d /etc/frankenphp ] && chown -R frankenphp:frankenphp /etc/frankenphp/

# --- Create systemd service ---
cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Liwan Web Analytics
After=network.target

[Service]
ExecStart=$INSTALL_DIR/liwan --config $CONFIG_DIR/liwan.config.toml
Restart=on-failure
User=$USERNAME
WorkingDirectory=$INSTALL_DIR

[Install]
WantedBy=multi-user.target
EOF

# --- Start services ---
systemctl daemon-reload
systemctl enable --now liwan
systemctl restart caddy || systemctl restart frankenphp || true

echo "✅ Liwan installed and running at: https://$DOMAIN"
echo "👉 First-time setup available in the logs: journalctl -u liwan -e"
