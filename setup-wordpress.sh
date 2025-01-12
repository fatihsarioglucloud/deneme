#!/bin/bash

# Parametreler
MYSQL_USER=$1
MYSQL_PASSWORD=$2
DOMAIN_NAME=$3
MYSQL_OLD_USER=$4
MYSQL_OLD_PASSWORD=$5

# Parametre kontrolü
if [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$DOMAIN_NAME" ] || [ -z "$MYSQL_OLD_USER" ] || [ -z "$MYSQL_OLD_PASSWORD" ]; then
  echo "Kullanım: $0 <Yeni MySQL Kullanıcı Adı> <Yeni MySQL Parolası> <Domain Adı> <Eski MySQL Kullanıcı Adı> <Eski MySQL Parolası>"
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

# MySQL yeni kullanıcı oluşturma, yetkilendirme ve eski kullanıcıyı silme
mysql -u adoptionv2user -padptnv2usr2025<<EOF
CREATE USER '$MYSQL_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO '$MYSQL_USER'@'localhost' WITH GRANT OPTION;
DROP USER 'adoptionv2user'@'localhost';
FLUSH PRIVILEGES;
EOF

if [ $? -ne 0 ]; then
  echo "MySQL işlemleri sırasında bir hata oluştu."
  exit 1
fi

# MySQL yeniden başlatma
systemctl restart mysql || { echo "MySQL yeniden başlatılamadı."; exit 1; }


echo "Tüm işlemler başarıyla tamamlandı."
