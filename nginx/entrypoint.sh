#!/bin/sh

DOMAIN="test.butal.ru"
CERT_DIR="/etc/letsencrypt/live/$DOMAIN"

if [ -s "$CERT_DIR/fullchain.pem" ] && [ -s "$CERT_DIR/privkey.pem" ]; then
    echo "HTTPS mode"
    cp /etc/nginx/templates/https.conf /etc/nginx/conf.d/default.conf
else
    echo "HTTP mode"
    cp /etc/nginx/templates/http.conf /etc/nginx/conf.d/default.conf
fi

nginx -g "daemon off;"
