#!/bin/bash

# Parametreler
MYSQL_USER=$1
MYSQL_PASSWORD=$2
DOMAIN_NAME=$3

# Parametre kontrolü
if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "Kullanım: $0 <MySQL Kullanıcı Adı> <MySQL Parolası> <Domain Adı>"
  exit 1
fi

# WordPress wp-config.php dosya yolu
WP_CONFIG_PATH="/var/www/html/adoptionv2user/wp-config.php"

# wp-config.php dosyasını kontrol et
if [ ! -f "$WP_CONFIG_PATH" ]; then
  echo "wp-config.php dosyası bulunamadı: $WP_CONFIG_PATH"
  exit 1
fi

# MySQL kullanıcı adı ve parola bilgilerini güncelle
sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', '$MYSQL_USER' );/" "$WP_CONFIG_PATH"
sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', '$MYSQL_PASSWORD' );/" "$WP_CONFIG_PATH"

# WordPress URL bilgilerini güncelle
sed -i "s|define( 'WP_HOME', '.*' );|define( 'WP_HOME', 'http://$DOMAIN_NAME' );|" "$WP_CONFIG_PATH"
sed -i "s|define( 'WP_SITEURL', '.*' );|define( 'WP_SITEURL', 'http://$DOMAIN_NAME' );|" "$WP_CONFIG_PATH"

# Nginx yapılandırması
NGINX_CONF="/etc/nginx/sites-available/default"
if [ -f "$NGINX_CONF" ]; then
  sed -i "s/server_name .*/server_name $DOMAIN_NAME;/" "$NGINX_CONF"
  echo "Nginx yapılandırması güncellendi."
else
  echo "Nginx yapılandırma dosyası bulunamadı: $NGINX_CONF"
  exit 1
fi

# Nginx yeniden başlatma
systemctl restart nginx || { echo "Nginx yeniden başlatılamadı."; exit 1; }

echo "Tüm işlemler başarıyla tamamlandı."
