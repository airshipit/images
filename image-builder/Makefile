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

SHELL		:= /bin/bash
COMMIT		?= $(shell git rev-parse HEAD)
LABEL		?= org.airshipit.build=community
IMAGE_NAME	?= image-builder
IMAGE_REGISTRY	?= quay.io
IMAGE_REPO	?= image-builder
IMAGE_TAG	?= latest
IMAGE_TYPE	?= iso # iso | qcow
PUSH_IMAGE	?= false
DISTRO          ?= ubuntu_focal
IMAGE		?= $(IMAGE_REGISTRY)/$(IMAGE_REPO):$(IMAGE_TAG)-${DISTRO}
IMAGE_ALIAS	?= $(IMAGE_REGISTRY)-$(IMAGE_REPO)-$(IMAGE_TAG)-${DISTRO}-${IMAGE_TYPE}
UEFI_BOOT	?=
PROXY           ?=
NO_PROXY        ?= localhost,127.0.0.1

.PHONY: help build images install_prereqs cut_image run

.ONESHELL:

help: ## This help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# Make target name that zuul expects for each project in this repo
images: build

install_prereqs:
ifneq ($(PROXY), )
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
endif
	sudo -E tools/install_prereqs.$(DISTRO)

build:
ifneq ($(PROXY), )
	sudo -E ./tools/docker_proxy.sh $(PROXY)
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
	sudo -E docker build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg http_proxy=$(PROXY) \
	--build-arg https_proxy=$(PROXY) \
	--build-arg HTTP_PROXY=$(PROXY) \
	--build-arg HTTPS_PROXY=$(PROXY) \
	--build-arg no_proxy=$(NO_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY) \
	--build-arg UEFI_BOOT=$(UEFI_BOOT) || exit 1
else
	sudo -E docker build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg UEFI_BOOT=$(UEFI_BOOT) || exit 1
endif
ifeq ($(PUSH_IMAGE), true)
	sudo -E docker push $(IMAGE)
endif

cut_image: install_prereqs
ifneq ($(PROXY), )
	sudo -E ./tools/docker_proxy.sh $(PROXY)
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
endif
	sudo -E tools/cut_image.sh $(IMAGE_TYPE) ./examples $(IMAGE) $(IMAGE_ALIAS) "$(UEFI_BOOT)" "$(PROXY)" "$(NO_PROXY)"

run: ## Run the iso in kvm for testing
	virsh start $(IMAGE_ALIAS)

tests:
	true

