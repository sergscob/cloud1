# Cloud-1 / WordPress Infrastructure Bootstrap

Ниже — минимальная production-like архитектура под требования проекта.

Стек:

* Nginx (reverse proxy + TLS)
* WordPress (PHP-FPM)
* MariaDB
* phpMyAdmin
* Docker Compose
* Persistent volumes
* Internal Docker network

---

# 📁 Структура проекта

```text
cloud-1/
├── docker-compose.yml
├── .env
├── nginx/
│   ├── Dockerfile
│   ├── conf/
│   │   └── default.conf
│   └── certs/
│       ├── cert.pem
│       └── key.pem
├── wordpress/
│   ├── Dockerfile
│   └── www.conf
├── mariadb/
│   ├── Dockerfile
│   └── init.sql
└── phpmyadmin/
    └── Dockerfile
```

---

# 📄 .env

```env
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wpuser
MYSQL_PASSWORD=wppassword

DOMAIN_NAME=localhost
```

---

# 🐳 docker-compose.yml

```yaml
version: '3.9'

services:
  nginx:
    build: ./nginx
    container_name: nginx
    restart: unless-stopped
    depends_on:
      - wordpress
      - phpmyadmin
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - internal

  wordpress:
    build: ./wordpress
    container_name: wordpress
    restart: unless-stopped
    depends_on:
      - mariadb
    environment:
      WORDPRESS_DB_HOST: mariadb:3306
      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}
      WORDPRESS_DB_USER: ${MYSQL_USER}
      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - wordpress_data:/var/www/html
    networks:
      - internal

  mariadb:
    build: ./mariadb
    container_name: mariadb
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
    networks:
      - internal

  phpmyadmin:
    build: ./phpmyadmin
    container_name: phpmyadmin
    restart: unless-stopped
    depends_on:
      - mariadb
    environment:
      PMA_HOST: mariadb
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    networks:
      - internal

volumes:
  wordpress_data:
  mariadb_data:

networks:
  internal:
    driver: bridge
```

---

# 🌐 nginx/Dockerfile

```dockerfile
FROM nginx:stable-alpine

COPY conf/default.conf /etc/nginx/conf.d/default.conf
COPY certs /etc/nginx/certs
```

---

# 🌐 nginx/conf/default.conf

```nginx
server {
    listen 80;
    server_name _;

    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;

    ssl_certificate /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location /phpmyadmin {
        proxy_pass http://phpmyadmin:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

# 🧠 wordpress/Dockerfile

```dockerfile
FROM wordpress:6.5-php8.2-fpm

COPY www.conf /usr/local/etc/php-fpm.d/www.conf

RUN mkdir -p /var/www/html
```

---

# 🧠 wordpress/[www.conf](http://www.conf)

```ini
[www]
user = www-data
group = www-data
listen = 9000
listen.owner = www-data
listen.group = www-data
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
```

---

# 🗄️ mariadb/Dockerfile

```dockerfile
FROM mariadb:11

COPY init.sql /docker-entrypoint-initdb.d/init.sql
```

---

# 🗄️ mariadb/init.sql

```sql
CREATE DATABASE IF NOT EXISTS wordpress;
```

---

# 🛠️ phpmyadmin/Dockerfile

```dockerfile
FROM phpmyadmin:latest
```

---

# 🔐 Production TLS with Let's Encrypt

Для production лучше использовать Let's Encrypt.

Домен:

```text
test.butal.ru
```

Домен должен указывать на IP VPS:

```dns
A record:

test.butal.ru -> YOUR_SERVER_IP
```

---

# 📁 Добавляем certbot сервис

Обновлённый docker-compose.yml:

```yaml
services:
  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - certbot_www:/var/www/certbot
      - certbot_conf:/etc/letsencrypt
```

Добавить volumes:

```yaml
volumes:
  wordpress_data:
  mariadb_data:
  certbot_www:
  certbot_conf:
```

---

# 🌐 Обновлённый nginx config

```nginx
server {
    listen 80;
    server_name test.butal.ru;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name test.butal.ru;

    ssl_certificate /etc/letsencrypt/live/test.butal.ru/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/test.butal.ru/privkey.pem;

    root /var/www/html;
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        fastcgi_pass wordpress:9000;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    location /phpmyadmin {
        proxy_pass http://phpmyadmin:80;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

# 🐳 nginx/Dockerfile

```dockerfile
FROM nginx:stable-alpine

COPY conf/default.conf /etc/nginx/conf.d/default.conf
```

---

# 🚀 Первый запуск

Сначала запускаем nginx без сертификатов:

```bash
docker compose up -d nginx
```

---

# 🔐 Получение сертификата

```bash
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email you@example.com \
  --agree-tos \
  --no-eff-email \
  -d test.butal.ru
```

После этого сертификаты появятся в:

```text
/etc/letsencrypt/live/test.butal.ru/
```

---

# 🔄 Перезапуск nginx

```bash
docker compose restart nginx
```

---

# 🔁 Автообновление сертификатов

Let's Encrypt сертификаты живут 90 дней.

Для Cloud-1 удобно вынести renew в отдельный lightweight container с cron.

---

# 📁 certbot-renew/

```text
certbot-renew/
├── Dockerfile
└── renew.sh
```

---

# 🐳 certbot-renew/Dockerfile

```dockerfile
FROM alpine:3.20

RUN apk add --no-cache \
    certbot \
    docker-cli \
    curl \
    bash

COPY renew.sh /renew.sh

RUN chmod +x /renew.sh

RUN echo "0 3 * * * /renew.sh >> /var/log/cron.log 2>&1" > /etc/crontabs/root

CMD ["crond", "-f", "-l", "2"]
```

---

# 📄 certbot-renew/renew.sh

```bash
#!/bin/sh

certbot renew

docker compose restart nginx
```

---

# 🐳 docker-compose.yml

Добавить сервис:

```yaml
  certbot-renew:
    build: ./certbot-renew
    container_name: certbot-renew
    restart: unless-stopped
    volumes:
      - certbot_conf:/etc/letsencrypt
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - internal
```

---

# 🧠 Как это работает

Контейнер:

* запускает cron daemon
* каждый день вызывает:

```bash
certbot renew
```

* после обновления перезапускает nginx

---

# ⚠️ Почему нужен docker.sock

```yaml
- /var/run/docker.sock:/var/run/docker.sock
```

Нужен чтобы контейнер мог выполнить:

```bash
docker compose restart nginx
```

---

# ⚠️ Security note

В production docker.sock давать контейнеру опасно.

Но для Cloud-1 это acceptable simplification.

Более production-подход:

* reload через host cron
* nginx reload API
* Traefik/Caddy auto TLS

---

# 🚀 Запуск

```bash
docker compose up -d --build
```

```bash
docker compose up -d --build
```

```bash
docker compose up -d --build
```

---

# ✅ Что уже покрывает эта архитектура

## ✔ Separate containers

* nginx
* wordpress
* mariadb
* phpmyadmin

## ✔ Persistence

Volumes:

* wordpress_data
* mariadb_data

## ✔ Automatic restart

```yaml
restart: unless-stopped
```

## ✔ Internal networking

MariaDB не публикуется наружу.

## ✔ TLS

Есть HTTPS.

## ✔ URL routing

```text
/              → WordPress
/phpmyadmin    → phpMyAdmin
```

---

# ⚠️ Что нужно будет добавить дальше

## 1. Ansible deployment

Автоматическая установка:

* Docker
* Docker Compose
* deploy compose stack

## 2. Let's Encrypt

Сейчас self-signed сертификат.

## 3. Healthchecks

Чтобы WordPress не стартовал раньше MySQL.

## 4. Secrets management

Сейчас пароли лежат в .env.

## 5. Firewall

Открыть только:

* 80
* 443
* 22

---

# 🧠 Важная архитектурная мысль

MariaDB НЕ имеет:

```yaml
ports:
  - "3306:3306"
```

Это правильно.

База доступна только внутри Docker network.

Это один из главных security points проекта.
