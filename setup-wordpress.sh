#!/bin/bash

# Parametreler
MYSQL_USER=$1
MYSQL_PASSWORD=$2
DOMAIN_NAME=$3
MYSQL_OLD_USERNAME=$4
MYSQL_OLD_PASSWORD=$5
# Parametre kontrolü
if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$DOMAIN_NAME" ]; then
  echo "Kullanım: $0 <MySQL Kullanıcı Adı> <MySQL Parolası> <Domain Adı>"
  exit 1
fi
# Yeni kullanıcı oluşturma
mysql -u root -p"$MYSQL_OLD_PASSWORD" -e "CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';"
mysql -u root -p"$MYSQL_OLD_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost';"
mysql -u root -p"$MYSQL_OLD_PASSWORD" -e "FLUSH PRIVILEGES;"
mysql -u root -p"$MYSQL_OLD_PASSWORD" -e  "exit;"
systemctl restart mysql
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

if grep -q "define('WP_HOME'" "$WP_CONFIG_PATH"; then
  sudo sed -i "s|define('WP_HOME', '.*');|$WP_HOME|" "$WP_CONFIG_PATH"
else
  echo "$WP_HOME" | sudo tee -a "$WP_CONFIG_PATH" > /dev/null
fi

if grep -q "define('WP_SITEURL'" "$WP_CONFIG_PATH"; then
  sudo sed -i "s|define('WP_SITEURL', '.*');|$WP_SITEURL|" "$WP_CONFIG_PATH"
else
  echo "$WP_SITEURL" | sudo tee -a "$WP_CONFIG_PATH" > /dev/null
fi

echo "wp-config.php dosyası başarıyla güncellendi: $WP_CONFIG_PATH"

# Nginx yapılandırmasını güncelle
NGINX_CONF="/etc/nginx/sites-available/default"

if [ -f "$NGINX_CONF" ]; then
  sed -i "s/server_name .*/server_name $DOMAIN_NAME;/" "$NGINX_CONF"
  echo "Nginx yapılandırması güncellendi."
else
  echo "Nginx yapılandırma dosyası bulunamadı: $NGINX_CONF"
  exit 1
fi

# Nginx yeniden başlatma
echo "Nginx yeniden başlatılıyor..."
if sudo systemctl restart nginx; then
  echo "Nginx başarıyla yeniden başlatıldı."
else
  echo "Nginx yeniden başlatılamadı."
  exit 1
fi

echo "Tüm işlemler başarıyla tamamlandı."
