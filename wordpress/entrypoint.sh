#!/bin/sh

set -eu

export WP_CLI_MEMORY_LIMIT="512M"

WORDPRESS_PATH="/var/www/html"
WORDPRESS_DB_HOST="${WORDPRESS_DB_HOST:-mariadb:3306}"
WORDPRESS_DB_NAME="${WORDPRESS_DB_NAME:-wordpress}"
WORDPRESS_DB_USER="${WORDPRESS_DB_USER:-wpuser}"
WORDPRESS_DB_PASSWORD="${WORDPRESS_DB_PASSWORD:-wppassword}"
DOMAIN_NAME="${DOMAIN_NAME:-test.butal.ru}"
WORDPRESS_URL="https://${DOMAIN_NAME:-https://test.butal.ru}"
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

until php -r '
$dbHost = getenv("WORDPRESS_DB_HOST") ?: "mariadb:3306";
$dbName = getenv("WORDPRESS_DB_NAME") ?: "wordpress";
$dbUser = getenv("WORDPRESS_DB_USER") ?: "wpuser";
$dbPassword = getenv("WORDPRESS_DB_PASSWORD") ?: "wppassword";

$dbPort = 3306;
$hostParts = explode(":", $dbHost, 2);
if (count($hostParts) === 2) {
    $dbHost = $hostParts[0];
    $dbPort = (int) $hostParts[1];
}

mysqli_report(MYSQLI_REPORT_OFF);

try {
    $mysqli = new mysqli($dbHost, $dbUser, $dbPassword, $dbName, $dbPort);
} catch (Throwable $exception) {
    fwrite(STDERR, $exception->getMessage() . PHP_EOL);
    exit(1);
}

if ($mysqli->connect_errno) {
    fwrite(STDERR, $mysqli->connect_error . PHP_EOL);
    exit(1);
}

exit(0);
'; do
    echo "Waiting for MariaDB..."
    sleep 2
done

if ! wp core is-installed --allow-root --path="$WORDPRESS_PATH" >/dev/null 2>&1; then
    wp core install \
        --allow-root \
        --path="$WORDPRESS_PATH" \
        --url="$WORDPRESS_URL" \
        --title="WordPress" \
        --admin_user="$WORDPRESS_ADMIN_USER" \
        --admin_password="$WORDPRESS_ADMIN_PASSWORD" \
        --admin_email="$WORDPRESS_ADMIN_EMAIL"
fi

exec docker-php-entrypoint php-fpm -F