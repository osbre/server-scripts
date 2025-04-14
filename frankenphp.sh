#!/bin/bash

set -e

if ! apt -q install jq; then
    echo "FAIL"
    exit 1
fi

wget -q "https://github.com/dunglas/frankenphp/releases/download/$(wget -q -O- 'https://api.github.com/repos/dunglas/frankenphp/releases/latest' | jq -r '.tag_name')/frankenphp-linux-$(uname -m)"

install -v "frankenphp-linux-$(uname -m)" "/usr/bin/frankenphp"
rm "frankenphp-linux-$(uname -m)"

if [[ ! $(grep -F "frankenphp" /etc/group) ]]
then
    groupadd --system frankenphp 
fi

if [[ ! $(grep -F "frankenphp" /etc/passwd) ]]
then
    useradd --system --gid frankenphp --create-home  --home-dir /var/lib/frankenphp --shell /usr/sbin/nologin frankenphp
fi

mkdir -p /etc/frankenphp

if [ ! -f "/etc/frankenphp/Caddyfile" ];
then
    echo -e "{\n}" > /etc/frankenphp/Caddyfile
fi

chown -R frankenphp:frankenphp /etc/frankenphp/

cat<<EOF > /etc/systemd/system/frankenphp.service
[Unit]
Description=FrankenPHP Server
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=frankenphp
Group=frankenphp
ExecStartPre=/usr/bin/frankenphp validate --config /etc/frankenphp/Caddyfile
ExecStart=/usr/bin/frankenphp run --environ --config /etc/frankenphp/Caddyfile
ExecReload=/usr/bin/frankenphp reload --config /etc/frankenphp/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable --now frankenphp