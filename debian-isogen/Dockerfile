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

ARG FROM=debian:stable

FROM ${FROM}

LABEL org.opencontainers.image.authors='airship-discuss@lists.airshipit.org, irc://#airshipit@freenode' \
      org.opencontainers.image.url='https://airshipit.org' \
      org.opencontainers.image.documentation='https://airship-images.readthedocs.org' \
      org.opencontainers.image.source='https://opendev.org/airship/images' \
      org.opencontainers.image.vendor='The Airship Authors' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN apt-get update && apt-get install -y \
    curl\
    debootstrap \
    grub-efi-amd64-bin \
    grub-pc-bin \
    mtools \
    squashfs-tools \
    xorriso \
    && rm -rf /var/lib/apt/lists/*

COPY files/ /builder/

RUN curl -L https://github.com/mikefarah/yq/releases/download/2.4.0/yq_linux_amd64 -o /bin/yq \
    && chmod +x /bin/yq

CMD /bin/bash /builder/build.sh
