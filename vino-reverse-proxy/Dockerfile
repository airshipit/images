FROM nginx:alpine

ENV BASIC_AUTH_USERNAME="username"
ENV BASIC_AUTH_PASSWORD="password"

RUN apk add --update --no-cache apache2-utils

COPY assets/default.conf /etc/nginx/conf.d/default.conf
COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh
