FROM nginx:stable-alpine

COPY conf /etc/nginx/templates
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]