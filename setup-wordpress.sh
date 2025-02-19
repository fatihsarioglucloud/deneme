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
sed -i "s|define( 'WP_HOME', '.*' );|define( 'WP_HOME', 'https://$DOMAIN_NAME' );|" "$WP_CONFIG_PATH"
sed -i "s|define( 'WP_SITEURL', '.*' );|define( 'WP_SITEURL', 'https://$DOMAIN_NAME' );|" "$WP_CONFIG_PATH"

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

# MySQL yeni kullanıcı oluşturma
echo "MySQL kullanıcı oluşturuluyor..."
sudo mysql -u root -e "CREATE USER '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'localhost' WITH GRANT OPTION;"
sudo mysql -u root -e "DROP USER 'adoptionv2user'@'localhost';"
sudo mysql -u root -e "FLUSH PRIVILEGES;"


if [ $? -ne 0 ]; then
  echo "MySQL işlemleri sırasında bir hata oluştu."
  exit 1
fi

# MySQL yeniden başlatma
echo "MySQL yeniden başlatılıyor..."
systemctl restart mysql || { echo "MySQL yeniden başlatılamadı."; exit 1; }

echo "Tüm işlemler başarıyla tamamlandı."
