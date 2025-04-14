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
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        *)
            echo "❌ Unknown argument: $1"
            exit 1
            ;;
    esac
done

# --- Validate required params ---
if [[ -z "${DOMAIN:-}" || -z "${EMAIL:-}" || -z "${PASSWORD:-}" ]]; then
    echo "❌ Usage: $0 --domain your.domain.com --email your@email.com --password your_password"
    exit 1
fi

# --- Variables ---
VERSION="1.3.1"
ARCH="amd64"
DOWNLOAD_URL="https://github.com/usefathom/fathom/releases/download/v${VERSION}/fathom_${VERSION}_linux_${ARCH}.tar.gz"
FATHOM_DIR="/var/lib/fathom"

# --- Install Fathom binary ---
wget -q "$DOWNLOAD_URL" -O /tmp/fathom.tar.gz
tar -C /usr/local/bin -xzf /tmp/fathom.tar.gz
chmod +x /usr/local/bin/fathom
rm /tmp/fathom.tar.gz

# --- Create fathom user ---
if ! getent group fathom >/dev/null; then
    groupadd --system fathom
fi

if ! id -u fathom >/dev/null 2>&1; then
    useradd --system --gid fathom --create-home --home-dir "$FATHOM_DIR" --shell /usr/sbin/nologin fathom
fi

mkdir -p "$FATHOM_DIR"

# --- Create .env config file ---
cat > "$FATHOM_DIR/.env" <<EOF
FATHOM_SERVER_ADDR=127.0.0.1:9000
FATHOM_GZIP=true
FATHOM_DEBUG=false
FATHOM_DATABASE_DRIVER="sqlite3"
FATHOM_DATABASE_NAME="fathom.db"
FATHOM_SECRET="$(openssl rand -hex 16)"
EOF

chown -R fathom:fathom "$FATHOM_DIR"

# --- Caddyfile for either FrankenPHP or Caddy ---
if command -v frankenphp >/dev/null; then
  CADDYFILE=/etc/frankenphp/Caddyfile
else
  CADDYFILE=/etc/caddy/Caddyfile
fi

# Start with an empty or existing file
touch "$CADDYFILE"

# Add email block if it doesn't exist
if ! grep -q "^\s*email\s" "$CADDYFILE"; then
    sed -i '1i\
{\
    email '"$EMAIL"'\
}\
' "$CADDYFILE"
fi

# Add or replace the domain block
# This simple approach overwrites any previous block for the domain
sed -i "/^$DOMAIN {/,/^}/d" "$CADDYFILE"
cat >> "$CADDYFILE" <<EOF

$DOMAIN {
    reverse_proxy 127.0.0.1:9000
}
EOF

chown -R frankenphp:frankenphp /etc/frankenphp/

# --- Systemd service for Fathom ---
cat > /etc/systemd/system/fathom.service <<EOF
[Unit]
Description=Fathom Analytics Server
After=network.target

[Service]
Type=simple
User=fathom
Group=fathom
WorkingDirectory=$FATHOM_DIR
ExecStart=/usr/local/bin/fathom server
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# --- Reload + enable services ---
systemctl daemon-reload
systemctl enable --now fathom
systemctl restart frankenphp

# --- Wait until server is up before registering user ---
echo "⏳ Waiting for Fathom to boot..."
sleep 3

# --- Register user ---
sudo -u fathom env -C "$FATHOM_DIR" /usr/local/bin/fathom user add --email="$EMAIL" --password="$PASSWORD"

echo "✅ Fathom installed and accessible at: https://$DOMAIN"
