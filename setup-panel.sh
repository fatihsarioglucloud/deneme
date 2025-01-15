#!/bin/bash

# Parametreler
DOMAIN_NAME=$1

# Parametre kontrolü
if [ -z "$DOMAIN_NAME" ]; then
  echo "Kullanım: $0 <Domain Adı>"
  exit 1
fi

# wp-config.php dosyasını kontrol et
if [ ! -f "$WP_CONFIG_PATH" ]; then
  echo "wp-config.php dosyası bulunamadı: $WP_CONFIG_PATH"
  exit 1
fi

# Nginx yapılandırması
NGINX_CONF="/home/azureuser/devops/nginx/default.conf"
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
