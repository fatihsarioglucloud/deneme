#!/bin/bash

# Parametreler
DB_USER=$1
DB_PASS=$2
DOMAIN_NAME=$3

if [ -z "$DB_USER" ] || [ -z "$DB_PASS" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "MySQL kullanıcı adı, parolası ve domain adı parametreleri eksik."
  exit 1
fi

# WordPress dizini
WORDPRESS_DIR="/var/www/html/adoptionv2user"
WP_CONFIG="$WORDPRESS_DIR/wp-config.php"

# wp-config.php dosyasındaki MySQL kullanıcı ve parola bilgilerini güncelleme
if [ -f "$WP_CONFIG" ]; then
  sudo sed -i "s/database_name_here/adoptionv2/" $WP_CONFIG
  sudo sed -i "s/username_here/$DB_USER/" $WP_CONFIG
  sudo sed -i "s/password_here/$DB_PASS/" $WP_CONFIG
else
  echo "wp-config.php dosyası bulunamadı."
  exit 1
fi

# Nginx yapılandırmasını güncelleme
NGINX_CONF="/etc/nginx/sites-available/default"
if [ -f "$NGINX_CONF" ]; then
  sudo sed -i "s/server_name _;/server_name $DOMAIN_NAME;/" $NGINX_CONF
else
  echo "Nginx yapılandırma dosyası bulunamadı."
  exit 1
fi

# Nginx yeniden başlatma
sudo systemctl restart nginx
