#!/bin/sh

DEBIAN_FRONTEND=noninteractive apt-get remove -y resolvconf
sed -i 's/domain-name-servers, domain-search, //' /etc/dhcp/dhclient.conf
service networking restart
sed -i '/nameserver/d' /etc/resolv.conf
export NAMESERVER=${NAMESERVER:-8.8.8.8}
export NAMESERVER_OTHER=${NAMESERVER_OTHER:-8.8.4.4}
echo 'nameserver '"$NAMESERVER" >> /etc/resolv.conf
echo 'nameserver '"$NAMESERVER_OTHER" >> /etc/resolv.conf
echo "nameserver is set"

apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https ca-certificates curl \
    software-properties-common

apt-get install -y docker.io

bash -c 'cat << EOF > /etc/docker/daemon.json
{
   "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF'

export APT_KEY_GPG_URL=${APT_KEY_GPG_URL:-https://packages.cloud.google.com/apt/doc/apt-key.gpg}
export K8S_IO_DEB_URL=${K8S_IO_DEB_URL:-http://apt.kubernetes.io/}

curl -s "$APT_KEY_GPG_URL" | sudo apt-key add -

bash -c 'cat << EOF > /etc/apt/sources.list.d/kubernetes.list
deb $K8S_IO_DEB_URL kubernetes-xenial main
EOF'

export K8S_VERSION=${K8S_VERSION:-1.19.0-00}

apt update

apt install -y kubelet="$K8S_VERSION" kubeadm="$K8S_VERSION" kubectl="$K8S_VERSION"

export CONTROL_PLANE_IP=${CONTROL_PLANE_IP:-172.24.4.199}

kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-cert-extra-sans="$CONTROL_PLANE_IP" \
  --control-plane-endpoint="$CONTROL_PLANE_IP"

mkdir -p /home/ubuntu/.kube

cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config

chown ubuntu:ubuntu /home/ubuntu/.kube/config

export CALICO_URL=${CALICO_URL:-https://docs.projectcalico.org/v3.15/manifests/calico.yaml}

export KUBECONFIG=/etc/kubernetes/admin.conf && \
kubectl apply -f "$CALICO_URL"