FROM ubuntu:18.04

SHELL ["bash", "-exc"]
ENV DEBIAN_FRONTEND noninteractive

ARG k8s_version=v1.18.3
ARG kubectl_url=https://storage.googleapis.com/kubernetes-release/release/"${k8s_version}"/bin/linux/amd64/kubectl


# Update distro and install common reqs
RUN apt-get update ;\
    apt-get dist-upgrade -y ;\
    apt-get install -y \
        python3-minimal \
        python3-pip \
        python3-setuptools \
        python3-libvirt \
        libvirt-clients \
        python3-netaddr \
        python3-lxml \
        curl \
        make \
        sudo \
        iproute2 \
        bridge-utils \
        iputils-ping \
        net-tools \
        less \
        jq \
        vim \
        openssh-client ;\
    curl -sSLo /usr/local/bin/kubectl "${kubectl_url}" ;\
    chmod +x /usr/local/bin/kubectl ;\
    pip3 install --upgrade pip ;\
    pip3 install --upgrade wheel ;\
    pip3 install --upgrade ansible ;\
    rm -rf /var/lib/apt/lists/*

COPY assets /opt/assets/
RUN cp -ravf /opt/assets/* / ;\
    rm -rf /opt/assets

RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh
