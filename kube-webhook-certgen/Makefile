
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
SHELL             := /bin/bash
PUSH_IMAGE        ?= false
IMAGE_NAME        ?= kube-webhook-certgen
DOCKER_REGISTRY   ?= quay.io
IMAGE_PREFIX      ?= airshipit
IMAGE_TAG         := v1.5.2
IMAGE             := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}
PROXY             ?= http://proxy.foo.com:8000
NO_PROXY          ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY         ?= false
all: check-docker images
check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi
images: check-docker
ifeq ($(USE_PROXY), true)
	docker pull jettech/kube-webhook-certgen:amd64-v1.5.2
	docker tag jettech/kube-webhook-certgen:amd64-v1.5.2 $(IMAGE)
else
	docker pull jettech/kube-webhook-certgen:amd64-v1.5.2
	docker tag jettech/kube-webhook-certgen:amd64-v1.5.2 $(IMAGE)
endif
ifeq ($(PUSH_IMAGE), true)
	docker push $(IMAGE)
endif
clean:
	docker rmi $(IMAGE)
tests:
	echo "Dummy Test to Pass gates"
.PHONY: all check-docker images clean tests