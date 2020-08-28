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

ARG GO_IMAGE=golang:1.14.4

ARG PYTHON_IMAGE=python:3.8

FROM ${GO_IMAGE} as builder

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

WORKDIR /home/build

COPY main.go go.mod go.sum ./
COPY config/ config/
COPY resource/ resource/

RUN go install /home/build
RUN go build -o capo-ephemeral /home/build

FROM ${PYTHON_IMAGE}

LABEL org.opencontainers.image.authors='airship-discuss@lists.airshipit.org, irc://#airshipit@freenode' \
      org.opencontainers.image.url='https://airshipit.org' \
      org.opencontainers.image.source='https://opendev.org/airship/images' \
      org.opencontainers.image.vendor='The Airship Authors' \
      org.opencontainers.image.licenses='Apache-2.0'

RUN set -ex && \
      pip install python-openstackclient

RUN set -ex && \
    apt-get update

RUN useradd -m bootstrap

USER bootstrap

WORKDIR /home/bootstrap

ENV HOME=/home/bootstrap

ENV PATH="${PATH}:${HOME}"

# Copy the binary from builder
COPY --from=builder /home/build/capo-ephemeral .

# Copy resources including scripts and help.txt file
COPY resource/* $HOME/

# Executes the go application capo-ephemeral
CMD ["capo-ephemeral"]