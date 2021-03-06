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

ARG AZ_SDK=mcr.microsoft.com/azure-cli:2.8.0
ARG GOLANG=golang:1.14.4

############################################
# Build GCP Bootstrap Container application
############################################
FROM ${GOLANG} as builder
WORKDIR /home/build
# copy the capg bootstrap container app code
COPY main.go .
COPY config/ config/
# Build capg bootstrap container application
RUN go mod init opendev.org/airship/images/bootstrap_capz && \
    go get -d -v ./... && \
    go install . && \
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o capz-ephemeral .

############################################
# Run Azure Bootstrap Container
############################################
FROM ${AZ_SDK}

LABEL org.opencontainers.image.authors='airship-discuss@lists.airshipit.org, irc://#airshipit@freenode' \
      org.opencontainers.image.url='https://airshipit.org' \
      org.opencontainers.image.documentation='https://opendev.org/airship/images/src/branch/master/bootstrap_capg/README.md' \
      org.opencontainers.image.source='https://opendev.org/airship/images' \
      org.opencontainers.image.vendor='The Airship Authors' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN adduser --disabled-password --gecos "" bootstrap
USER bootstrap

WORKDIR /home/bootstrap
ENV HOME=/home/bootstrap
ENV PATH="${PATH}:${HOME}"

# Copy the Azure Bootstrap Container command
COPY --from=builder /home/build/capz-ephemeral .
# Copy help file
COPY assets/help.txt .

# Executes the Azure Bootstrap command
CMD ["capz-ephemeral"]
