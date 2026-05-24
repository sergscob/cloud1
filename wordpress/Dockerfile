FROM wordpress:6.5-php8.2-fpm

RUN apt-get update \
	&& apt-get install -y --no-install-recommends curl ca-certificates \
	&& rm -rf /var/lib/apt/lists/* \
	&& curl -fsSL -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x /usr/local/bin/wp \
	&& echo "memory_limit = 512M" > /usr/local/etc/php/conf.d/99-memory-limit.ini

COPY www.conf /usr/local/etc/php-fpm.d/www.conf
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh \
	&& mkdir -p /var/www/html

ENTRYPOINT ["/entrypoint.sh"]