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
IMAGE_ID          ?= none
COMMIT            ?= $(shell git rev-parse HEAD)
LABEL             ?= org.airshipit.build=community
IMAGE_NAME        ?= ipa
DOCKER_REGISTRY   ?= quay.io
IMAGE_PREFIX      ?= airshipit
IMAGE_TAG         ?= latest
IMAGE_IPA_NAME    ?= ipabuilder
BRANCH            ?= stable/victoria
IMAGE             := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}
IMAGE_IPABUILDER  := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_IPA_NAME}:${IMAGE_TAG}
PROXY             ?= http://proxy.foo.com:8000
NO_PROXY          ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY         ?= false


build_ipa:
ifeq ($(USE_PROXY), true)
	sudo docker build . \
	--tag $(IMAGE_IPABUILDER) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg BRANCH=$(BRANCH) \
	--build-arg http_proxy=$(PROXY) \
	--build-arg https_proxy=$(PROXY) \
	--build-arg HTTP_PROXY=$(PROXY) \
	--build-arg HTTPS_PROXY=$(PROXY) \
	--build-arg no_proxy=$(NO_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY)

	sudo docker run --name ipabuilder \
	--privileged $(IMAGE_IPABUILDER) \
	/bin/bash -c "export PATH=$$PATH:/root/.local/bin/ && \
	export http_proxy=$(PROXY) && export https_proxy=$(PROXY) && \
	ironic-python-agent-builder -o ipa-ubuntu-master -b HEAD -v --extra-args=--no-tmpfs -e devuser ubuntu"
else
	sudo docker build . \
	--tag $(IMAGE_IPABUILDER) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg BRANCH=$(BRANCH)

	sudo docker run --name ipabuilder \
	--privileged $(IMAGE_IPABUILDER) \
	/bin/bash -c "export PATH=$$PATH:/root/.local/bin/ && \
	ironic-python-agent-builder -o ipa-ubuntu-master -b HEAD -v --extra-args=--no-tmpfs -e devuser ubuntu"
endif

	sudo docker cp $$(sudo docker ps -a | grep ipabuilder | awk '{print $$1}'):/ipa-ubuntu-master.initramfs .
	sudo docker cp $$(sudo docker ps -a | grep ipabuilder | awk '{print $$1}'):/ipa-ubuntu-master.kernel .


	sudo docker build . -f Dockerfile.ipa \
	--tag $(IMAGE) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)"

ifeq ($(PUSH_IMAGE), true)
	docker push $(IMAGE)
endif


images: build_ipa

tests:
	echo TODO

.PHONY: images build_ipa tests
