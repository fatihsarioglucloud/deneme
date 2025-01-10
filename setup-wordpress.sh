#!/bin/bash

# Güncellemeler
sudo apt update -y
sudo apt upgrade -y

# WordPress için mevcut klasör ve izinleri kontrol et
WORDPRESS_DIR="/var/www/html/adoptionv2user"
if [ ! -d "$WORDPRESS_DIR" ]; then
  echo "WordPress dizini bulunamadı: $WORDPRESS_DIR"
  exit 1
fi

# Nginx ve PHP kurulumu (sadece gerekli modülleri yükle)
sudo apt install -y php7.4-fpm php7.4-mysql

# MySQL Veritabanı ve Kullanıcı Ayarları
DB_NAME="adoptionv2"
DB_USER="adoptionv2user"
DB_PASS="StrongPassword123"

# Veritabanı ve kullanıcı oluşturuluyor
sudo mysql -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
sudo mysql -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

# WordPress wp-config.php ayarları
WP_CONFIG="$WORDPRESS_DIR/wp-config.php"
if [ ! -f "$WP_CONFIG" ]; then
  echo "wp-config.php bulunamadı: $WP_CONFIG"
  exit 1
fi

# Veritabanı bilgilerini wp-config.php dosyasına yaz
sudo sed -i "s/database_name_here/${DB_NAME}/" $WP_CONFIG
sudo sed -i "s/username_here/${DB_USER}/" $WP_CONFIG
sudo sed -i "s/password_here/${DB_PASS}/" $WP_CONFIG

# Nginx yapılandırmasını güncelleme
NGINX_CONF="/etc/nginx/sites-available/default"
if [ ! -f "$NGINX_CONF" ]; then
  echo "Nginx yapılandırma dosyası bulunamadı: $NGINX_CONF"
  exit 1
fi

# Nginx yapılandırmasını düzenle
sudo bash -c 'cat > /etc/nginx/sites-available/default' << EOL
server {
    listen 80;
    root $WORDPRESS_DIR;
    index index.php index.html index.htm;
    server_name _;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
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
