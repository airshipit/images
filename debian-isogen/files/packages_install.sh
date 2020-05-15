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
echo "debian-live" > /etc/hostname
echo "127.0.0.1 localhost" > /etc/hosts
apt-get update && apt-get install  -y --no-install-recommends \
   linux-image-amd64 \
   live-boot \
   systemd-sysv\
   apt-transport-https \
   openssh-server \
   curl \
   gnupg \
   iptables \
   ifenslave \
   bridge-utils \
   tcpdump \
   iputils-ping \
   vlan
UNSTABLE_REPO="deb http://ftp.debian.org/debian unstable main"
echo "${UNSTABLE_REPO}" >> /etc/apt/sources.list.d/unstable.list

# ensure we support bonding and 802.1q

echo 'bonding' >> /etc/modules
echo '8021q' >> /etc/modules

apt-get update && apt-get install  -y --no-install-recommends \
      cloud-init
rm -rf /etc/apt/sources.list.d/unstable.list /var/lib/apt/lists/*


