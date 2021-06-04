ARG FROM=bitnami/minideb
FROM ${FROM}

LABEL org.opencontainers.image.authors='airship-discuss@lists.airshipit.org, irc://#airshipit@freenode' \
      org.opencontainers.image.url='https://airshipit.org' \
      org.opencontainers.image.documentation='https://airshipit.readthedocs.io' \
      org.opencontainers.image.source='https://opendev.org/airship/images' \
      org.opencontainers.image.vendor='The Airship Authors' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN set -xe \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -qq && apt-get -y dist-upgrade \
    && apt-get install -y gnutls-bin \
    && apt-get autoremove -y --purge \
    && apt-get clean \
    && rm -rf /var/lib/apt-get/lists/*

CMD ["/bin/bash"]
