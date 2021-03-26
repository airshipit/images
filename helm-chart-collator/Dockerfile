FROM ubuntu:focal as chart-collator

SHELL ["bash", "-exc"]
ENV DEBIAN_FRONTEND noninteractive

# Update distro and install ansible and git
RUN apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y --no-install-recommends \
        python3-minimal \
        python3-pip \
        python3-apt \
        python3-setuptools \
        openssh-client \
        jq \
        git && \
    pip3 install --upgrade wheel --trusted-host pypi.org \
                 --trusted-host files.pythonhosted.org && \
    pip3 install --upgrade ansible --trusted-host pypi.org \
                 --trusted-host files.pythonhosted.org && \
    pip3 install --upgrade jmespath --trusted-host pypi.org \
                 --trusted-host files.pythonhosted.org && \
    pip3 install --upgrade yq --trusted-host pypi.org \
                 --trusted-host files.pythonhosted.org && \
    rm -rf /var/lib/apt/lists/*

COPY playbooks /opt/playbooks
COPY config /opt/config

ARG CHARTS="/opt/config/charts.yaml"
RUN ansible-playbook -v /opt/playbooks/create_repository.yaml \
  -i /opt/playbooks/inventory.yaml \
  --extra-vars "CHARTS=$CHARTS"

FROM chartmuseum/chartmuseum:latest

COPY --from=chart-collator /charts /charts

ENTRYPOINT /chartmuseum --debug --port=8080 \
    --storage="local" \
    --storage-local-rootdir=/charts
