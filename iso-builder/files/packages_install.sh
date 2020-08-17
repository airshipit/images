#!/bin/bash
# Copyright 2018 AT&T Intellectual Property.  All other rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -xe
echo "ubuntu-live" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
echo "deb http://archive.ubuntu.com/ubuntu focal universe" >> /etc/apt/sources.list
apt-get update && apt-get install  -y --no-install-recommends \
   linux-generic \
   live-boot \
   systemd-sysv \
   apt-transport-https \
   openssh-server \
   curl \
   gnupg \
   iptables \
   ifenslave \
   bridge-utils \
   tcpdump \
   iputils-ping \
   vlan \
   locales \
   lsb-release \
   ebtables

# ensure we support bonding and 802.1q
echo 'bonding' >> /etc/modules
echo '8021q' >> /etc/modules

locale-gen en_US.UTF-8
systemctl enable systemd-networkd
echo 'br_netfilter' >> /etc/modules

apt-get install  -y --no-install-recommends \
   cloud-init

rm -rf /var/lib/apt/lists/*
