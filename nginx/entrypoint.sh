#!/bin/sh

DOMAIN="test.butal.ru"

if [ -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem ]; then
    echo "HTTPS mode"
    cp /etc/nginx/templates/https.conf /etc/nginx/conf.d/default.conf
else
    echo "HTTP mode"
    cp /etc/nginx/templates/http.conf /etc/nginx/conf.d/default.conf
fi

nginx -g "daemon off;"
