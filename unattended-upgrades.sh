#!/bin/bash

set -e

echo "Installing unattended-upgrades..."
sudo apt update
sudo apt install -y unattended-upgrades apt-listchanges

echo "Enabling unattended-upgrades..."
sudo dpkg-reconfigure --priority=low unattended-upgrades

echo "Creating 20auto-upgrades config..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::Verbose "1";  # Log to /var/log/apt/history.log
EOF

echo "Ensuring /etc/apt/apt.conf.d/50unattended-upgrades is configured..."
sudo sed -i 's|//\(.*"${distro_id}:${distro_codename}-security";\)|\1|' /etc/apt/apt.conf.d/50unattended-upgrades

echo "Done. Unattended upgrades are now configured."
