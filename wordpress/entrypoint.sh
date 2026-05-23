#!/bin/sh

set -eu

WORDPRESS_PATH="/var/www/html"
WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"
WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wpuser}"
WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wppassword}"
WORDPRESS_URL="${WORDPRESS_URL:-http://localhost}"
WORDPRESS_SITE_TITLE="${WORDPRESS_SITE_TITLE:-WordPress}"
WORDPRESS_ADMIN_USER="${WORDPRESS_ADMIN_USER:-admin}"
WORDPRESS_ADMIN_PASSWORD="${WORDPRESS_ADMIN_PASSWORD:-admin12345}"
WORDPRESS_ADMIN_EMAIL="${WORDPRESS_ADMIN_EMAIL:-admin@example.com}"

cd "$WORDPRESS_PATH"

if [ ! -f wp-config.php ]; then
    wp core download --allow-root --path="$WORDPRESS_PATH" --quiet
    wp config create \
        --allow-root \
        --path="$WORDPRESS_PATH" \
        --dbname="$WORDPRESS_DB_NAME" \
        --dbuser="$WORDPRESS_DB_USER" \
        --dbpass="$WORDPRESS_DB_PASSWORD" \
        --dbhost="$WORDPRESS_DB_HOST" \
        --skip-check \
        --force \
        --quiet
fi

until wp db query 'SELECT 1' --allow-root --path="$WORDPRESS_PATH" >/dev/null 2>&1; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if ! wp core is-installed --allow-root --path="$WORDPRESS_PATH" >/dev/null 2>&1; then
    wp core install \
        --allow-root \
        --path="$WORDPRESS_PATH" \
        --url="$WORDPRESS_URL" \
        --title="$WORDPRESS_SITE_TITLE" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL"
fi

exec docker-php-entrypoint php-fpm -F