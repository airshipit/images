FROM nginx:alpine

ENV USE_BASIC_AUTH="false"
ENV BASIC_AUTH_USERNAME="username"
ENV BASIC_AUTH_PASSWORD="password"

ENV USE_TLS="false"
ENV TLS_CRT=""
ENV TLS_KEY=""

RUN apk add --update --no-cache apache2-utils ;

COPY assets/default.conf.tpl /default.conf.tpl
COPY assets/entrypoint.sh /entrypoint.sh

ENTRYPOINT /entrypoint.sh
