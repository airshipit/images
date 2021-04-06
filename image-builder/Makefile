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
DOCKER_REGISTRY	?= quay.io
IMAGE_PREFIX	?= airshipit
IMAGE_TAG	?= latest
IMAGE_TYPE	?= iso # iso | qcow
PUSH_IMAGE	?= false
DISTRO          ?= ubuntu_focal
WORKDIR         ?= ./manifests
QCOW_BUNDLE     ?= ${WORKDIR}/qcow-bundle
# Specify if you want to only build a certain subset of QCOW bundles
QCOW_BUNDLE_DIRS  ?=
# Set to true to skip multistrap.sh script. Useful for testing
SKIP_MULTISTRAP ?=
# Set to true to skip multistrap playbook. Useful for testing
SKIP_MULTI_ROLE ?=
# Set to true to skip osconfig playbook. Useful for testing
SKIP_OSCONFIG_ROLE ?=
# Set to true to skip livecdcontent playbook. Useful for testing
SKIP_LIVECDCONTENT_ROLE ?=
IMAGE           ?= ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}-${DISTRO}
PROXY           ?=
NO_PROXY        ?= localhost,127.0.0.1

.PHONY: help build images cut_image package_qcow run clean

.ONESHELL:

help: ## This help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

# Make target name that zuul expects for each project in this repo
images: build generate_iso package_qcow clean

build:
	set -ex
	# Apply any user-defined rootfs overrides to playbooks
	cp $(WORKDIR)/rootfs/multistrap-vars.yaml assets/playbooks/roles/multistrap/vars/main.yaml
	cp $(WORKDIR)/rootfs/osconfig-vars.yaml assets/playbooks/roles/osconfig/vars/main.yaml
	cp $(WORKDIR)/rootfs/livecdcontent-vars.yaml assets/playbooks/roles/livecdcontent/vars/main.yaml
ifneq ($(PROXY), )
	sudo -E ./tools/docker_proxy.sh $(PROXY) $(NO_PROXY)
	export http_proxy=$(PROXY)
	export https_proxy=$(PROXY)
	export no_proxy=$(NO_PROXY)
	export HTTP_PROXY=$(PROXY)
	export HTTPS_PROXY=$(PROXY)
	export NO_PROXY=$(NO_PROXY)
ifneq ($(SKIP_MULTISTRAP), true)
	sudo -E ./tools/multistrap.sh $(WORKDIR)
endif
	sudo -E DOCKER_BUILDKIT=1 docker -D -l debug build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
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
ifneq ($(SKIP_MULTISTRAP), true)
	sudo -E ./tools/multistrap.sh $(WORKDIR)
endif
	sudo -E DOCKER_BUILDKIT=1 docker -D -l debug build --tag $(IMAGE) -f Dockerfile.$(DISTRO) . \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)"
endif
	imgId=`sudo docker images | grep 'image-builder ' | awk '{print $$3}'`
	sudo -E DOCKER_BUILDKIT=1 docker run $$imgId ls -ltra /build/usr/bin/sudo > /tmp/sticky_result
	sudo grep '^-rws' /tmp/sticky_result >& /dev/null || \
		(echo Could not find sticky bit set on target image sudo binary. Are you using buildkit? && \
		sudo cat /tmp/sticky_result && exit 1)
ifeq ($(PUSH_IMAGE), true)
	sudo -E DOCKER_BUILDKIT=1 docker push $(IMAGE)
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
ifeq ($(IMAGE_TYPE), iso)
	sudo -E tools/cut_image.sh $(IMAGE_TYPE) $(WORKDIR)/iso $(IMAGE) "$(PROXY)" "$(NO_PROXY)"
else
	# Assemble all images based on configs defined in each subdirectory
	#                     Trailing / allows proper function with symlinks
	iterDirs="$$(find $(QCOW_BUNDLE)/ -maxdepth 1 -mindepth 1 -type d -exec basename {} \;)"
	if [[ -z $$iterDirs ]]; then
	    echo "Could not find any qcow images defined for bundle - exiting."
	    exit 1
	fi
	for subdir in $$iterDirs; do
	    # QCOW configs
	    export osconfig_params="$(QCOW_BUNDLE)/$$subdir/osconfig-vars.yaml"
	    export qcow_params="$(QCOW_BUNDLE)/$$subdir/qcow-vars.yaml"
	    # Image name
	    export img_name=$$subdir.qcow2
	    sudo -E tools/cut_image.sh $(IMAGE_TYPE) $(QCOW_BUNDLE) $(IMAGE) "$(PROXY)" "$(NO_PROXY)"
	done
endif

generate_iso:
	set -ex
	export IMAGE_TYPE=iso
	sudo -E make cut_image

package_qcow:
	set -ex
	export IMAGE_TYPE=qcow
ifneq ($(QCOW_BUNDLE_DIRS), )
	bundleDirs="$(QCOW_BUNDLE_DIRS)"
else
	# Assemble all images based on configs defined in each $(IMAGE_TYPE)* subdirectory
	#                   Trailing / allows proper function with symlinks
	bundleDirs="$$(find $(WORKDIR)/ -maxdepth 1 -mindepth 1 -name "qcow-bundle*" -type d -exec basename {} \;)"
endif
	if [[ -z $$bundleDirs ]]; then
	    echo "Could not find any qcow bundle directories - exiting."
	    exit 1
	fi
	for bundledir in $$bundleDirs; do
	    export QCOW_BUNDLE="$(WORKDIR)/$$bundledir"
	    sudo -E make cut_image
	    sudo -E DOCKER_BUILDKIT=1 docker -D -l debug build --tag $(DOCKER_REGISTRY)/$(IMAGE_PREFIX)/$$bundledir:$(IMAGE_TAG)-$(DISTRO) -f Dockerfile-qcow.$(DISTRO) $(WORKDIR)/$$bundledir \
	    --label $(LABEL) \
	    --label "org.opencontainers.image.revision=$(COMMIT)" \
	    --label "org.opencontainers.image.created=\
	    $(shell date --rfc-3339=seconds --utc)" \
	    --label "org.opencontainers.image.title=$(DOCKER_REGISTRY)/$(IMAGE_PREFIX)/$$bundledir:$(IMAGE_TAG)-$(DISTRO)"
ifeq ($(PUSH_IMAGE), true)
	    sudo -E DOCKER_BUILDKIT=1 docker push $(DOCKER_REGISTRY)/$(IMAGE_PREFIX)/$$bundledir:$(IMAGE_TAG)-$(DISTRO)
endif
	done

tests:
	true

clean:
	set -ex
	sudo -E tools/multistrap.sh clean
	find $(WORKDIR) -name "*.iso" -exec rm {} \; >& /dev/null
	find $(WORKDIR) -name "*.qcow2" -exec rm {} \; >& /dev/null
	find $(WORKDIR) -name "*.md5sum" -exec rm {} \; >& /dev/null
