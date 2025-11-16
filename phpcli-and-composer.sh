#!/bin/bash

# Update and install necessary packages
apt update
apt install -y lsb-release apt-transport-https ca-certificates curl

# Add Ondřej Surý's PHP repository
# curl -fsSL https://packages.sury.org/php/README.txt | sudo bash -
if [ "$(whoami)" != "root" ]; then
    SUDO=sudo
fi

${SUDO} apt-get update
${SUDO} apt-get -y install lsb-release ca-certificates curl
${SUDO} curl -sSLo /tmp/debsuryorg-archive-keyring.deb https://packages.sury.org/debsuryorg-archive-keyring.deb
${SUDO} dpkg -i /tmp/debsuryorg-archive-keyring.deb
${SUDO} sh -c 'echo "deb [signed-by=/usr/share/keyrings/debsuryorg-archive-keyring.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list'
${SUDO} apt-get update
# end add repository

# Install PHP 8.4 and required extensions for Laravel
apt install -y unzip php8.4-cli php8.4-mbstring php8.4-xml php8.4-mysql php8.4-curl php8.4-bcmath php8.4-zip php8.4-soap php8.4-intl php8.4-common php8.4-opcache php8.4-pgsql php8.4-sqlite3 php-pear php8.4-dev g++ make

# Set PHP 8.4 as default
update-alternatives --set php /usr/bin/php8.4
update-alternatives --set phpize /usr/bin/phpize8.4
update-alternatives --set php-config /usr/bin/php-config8.4

# Install Composer globally
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

# Verify PHP and Composer installation
php -v
php -m
composer --version

echo "PHP 8.4 and Composer have been installed successfully!"
