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

# Install PHP 8.5 and required extensions for Laravel
apt install -y unzip php8.5-cli php8.5-mbstring php8.5-xml php8.5-mysql php8.5-curl php8.5-bcmath php8.5-redis php8.5-zip php8.5-soap php8.5-intl php8.5-common php8.5-pgsql php8.5-sqlite3 php-pear php8.5-dev g++ make

# Set PHP 8.5 as default
update-alternatives --set php /usr/bin/php8.5
update-alternatives --set phpize /usr/bin/phpize8.5
update-alternatives --set php-config /usr/bin/php-config8.5

# Install Composer globally
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

php -v
php -m

pecl install openswoole
echo "extension=openswoole.so" >> /etc/php/8.5/cli/php.ini
