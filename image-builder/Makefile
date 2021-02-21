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
QCOW_IMAGE_NAME ?= qcow-bundle
DOCKER_REGISTRY	?= quay.io
IMAGE_PREFIX	?= airshipit
IMAGE_TAG	?= latest
IMAGE_TYPE	?= iso # iso | qcow
PUSH_IMAGE	?= false
DISTRO          ?= ubuntu_focal
WORKDIR         ?= ./config
QCOW_CONF_DIRS  ?=
IMAGE           ?= ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}-${DISTRO}
QCOW_IMAGE      ?= ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}-${QCOW_IMAGE_NAME}
PROXY           ?=
NO_PROXY        ?= localhost,127.0.0.1

.PHONY: help build images cut_image package_qcow run clean

.ONESHELL:

help: ## This help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# Make target name that zuul expects for each project in this repo
images: build generate_iso package_qcow

build:
	set -ex
	# Apply any user-defined overrides to multistrap playbook
	cp $(WORKDIR)/rootfs/multistrap-vars.yaml assets/playbooks/roles/multistrap/vars/main.yaml
ifneq ($(PROXY), )
	sudo -E ./tools/docker_proxy.sh $(PROXY) $(NO_PROXY)
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
	sudo -E ./tools/multistrap.sh
	sudo -E docker -D -l debug build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
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
	--build-arg NO_PROXY=$(NO_PROXY)
else
	sudo -E ./tools/multistrap.sh
	sudo -E docker -D -l debug build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)"
endif
ifeq ($(PUSH_IMAGE), true)
	sudo -E docker push $(IMAGE)
endif

cut_image:
	set -ex
ifneq ($(PROXY), )
	sudo -E ./tools/docker_proxy.sh $(PROXY) $(NO_PROXY)
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
endif
ifneq ($(EXPLICIT_DIRS), )
	iterDirs="$(EXPLICIT_DIRS)"
else
	# Assemble all images based on configs defined in each $(IMAGE_TYPE)* subdirectory
	iterDirs=`find $(WORKDIR) -name "$(IMAGE_TYPE)*" -type d -exec basename {} \;`
endif
	for subdir in $$iterDirs; do
	    # ISO configs
	    export user_data=$(WORKDIR)/$$subdir/user_data
	    export network_config=$(WORKDIR)/$$subdir/network_data.json
	    # QCOW configs
	    export osconfig_params=$(WORKDIR)/$$subdir/osconfig-*-vars.yaml
	    export qcow_params=$(WORKDIR)/$$subdir/qcow-*-vars.yaml
	    # Shared configs
	    export img_name=$$(cat $(WORKDIR)/$$subdir/img_name)
	    sudo -E tools/cut_image.sh $(IMAGE_TYPE) $(WORKDIR) $(IMAGE) "$(PROXY)" "$(NO_PROXY)"
	done

generate_iso:
	set -ex
	export IMAGE_TYPE=iso
	sudo -E make cut_image

package_qcow:
	set -ex
	export IMAGE_TYPE=qcow
	export EXPLICIT_DIRS=$(QCOW_CONF_DIRS)
	sudo -E make cut_image
	sudo -E docker -D -l debug build --tag $(QCOW_IMAGE) -f Dockerfile-qcow.$(DISTRO) $(WORKDIR) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(QCOW_IMAGE_NAME)"
ifeq ($(PUSH_IMAGE), true)
	sudo -E docker push $(QCOW_IMAGE)
endif

tests:
	true

clean:
	set -ex
	sudo -E tools/multistrap.sh clean
	rm $(WORKDIR)/*.iso
	rm $(WORKDIR)/*.qcow2
	rm $(WORKDIR)/*.md5sum
