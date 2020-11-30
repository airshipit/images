FROM ubuntu:20.04 as downloader
ARG BRANCH=stable/victoria

ENV DIB_DHCP_TIMEOUT=60 \
    DIB_REPOLOCATION_ironic_python_agent=/ironic-python-agent \
    DIB_REPOLOCATION_requirements=/requirements \
    DIB_DEV_USER_USERNAME=devuser \
    DIB_DEV_USER_PASSWORD=password \
    DIB_DEV_USER_PWDLESS_SUDO=yes \
    AUTHORIZE_SSH=true \
    DEBIAN_FRONTEND=noninteractive


RUN set -ex ;\
    apt-get update ;\
    apt-get install git python3-pip qemu-utils sudo curl squashfs-tools cpio -y ;\
    git clone https://opendev.org/openstack/ironic-python-agent.git -b ${BRANCH} /ironic-python-agent ;\
    git clone https://opendev.org/openstack/requirements.git -b ${BRANCH} /requirements ;\
    pip3 install --user diskimage-builder ironic-python-agent-builder
