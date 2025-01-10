#!/bin/bash

# Güncellemeler
sudo apt update -y
sudo apt upgrade -y

# Nginx ve PHP kurulumu
sudo apt install -y nginx php7.4 php7.4-fpm php7.4-mysql

# WordPress için gerekli klasörlerin oluşturulması
sudo mkdir -p /var/www/html
sudo chmod -R 755 /var/www/html

# MySQL Veritabanı Oluşturma
DB_NAME="adoptionv2"
DB_USER="adoptionv2user"
DB_PASS="StrongPassword123"
sudo mysql -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# WordPress İndirme ve Yükleme
sudo wget -O /tmp/latest.tar.gz https://wordpress.org/latest.tar.gz
sudo tar -xzf /tmp/latest.tar.gz -C /var/www/html --strip-components=1
sudo chown -R www-data:www-data /var/www/html

# WordPress wp-config.php ayarları
sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" /var/www/html/wp-config.php

# Nginx yapılandırması
sudo bash -c 'cat > /etc/nginx/sites-available/default' << EOL
server {
    listen 80;
    root /var/www/html;
    index index.php index.html index.htm;
    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOL

# Nginx yeniden başlatma
sudo systemctl restart nginx
