FROM ubuntu:18.04 as downloader

ARG IPA_BASEURI=https://images.rdoproject.org/master/rdo_trunk/current-tripleo/ironic-python-agent.tar

RUN set -ex ;\
    apt-get update ;\
    apt-get install curl -y

RUN set -ex ;\
    curl -sSL -o /tmp/ironic-python-agent.tar $IPA_BASEURI ;\
    mkdir -p /tmp/ironic-python-agent ;\
    tar -xf /tmp/ironic-python-agent.tar -C /tmp/ironic-python-agent

FROM ubuntu:18.04 as dist

COPY --from=downloader /tmp/ironic-python-agent /

RUN useradd airship --create-home --shell=/bin/bash

USER airship

WORKDIR /home/airship/