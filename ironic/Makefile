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

SHELL                := /bin/bash
BUILD_DIR            ?= build
PUSH_IMAGE           ?= false
IMAGE_ID             ?= none
COMMIT               ?= $(shell git rev-parse HEAD)
LABEL                ?= org.airshipit.build=community
DOCKER_REGISTRY      ?= quay.io
IMAGE_PREFIX         ?= airshipit
OPENSTACK_VERSION    ?= stable/ussuri
DISTRO               ?= ubuntu_bionic
OS_VER               =  $(word 2, $(subst /, ,$(OPENSTACK_VERSION)))
IMAGE_NAME           ?= ironic
IMAGE_TAG            ?= ${OS_VER}-${DISTRO}
IMAGE_IRONIC         := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}
IMAGE_REQUIREMENTS   := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/requirements:${IMAGE_TAG}
IMAGE_LOCI_WHEELS    := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/loci_wheels:${IMAGE_TAG}
SH_TO_CHECK          := $(wildcard files/*.sh )
PROXY                ?= http://proxy.foo.com:8000
NO_PROXY             ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY            ?= false
BASE_IMAGE           ?= docker.io/ubuntu:bionic
ironic_profiles      ?= "fluent ipxe ipmi qemu tftp"
ironic_pip_packages  ?= "pycrypto python-openstackclient sushy"
ironic_dist_packages ?= "ethtool lshw iproute2"

all: lint images

check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi

images: check-docker build_requirements build_loci_wheels run_wheel_srvr build_ironic

docs: clean build_docs

build_docs:
	echo TODO

build_requirements:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
ifeq ($(USE_PROXY), true)
	http_proxy=$(PROXY) https_proxy=$(PROXY) \
	HTTP_PROXY=$(PROXY) HTTPS_PROXY=$(PROXY) \
	no_proxy=$(NO_PROXY) NO_PROXY=$(NO_PROXY) \
	docker build --force-rm --pull --no-cache \
	https://git.openstack.org/openstack/loci.git \
	--network host \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_REQUIREMENTS) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg PYTHON3=yes \
	--build-arg FROM=${BASE_IMAGE} \
	--build-arg PROJECT=requirements \
	--build-arg PROJECT_REF=${OPENSTACK_VERSION} \
	--build-arg http_proxy=$(PROXY) \
	--build-arg https_proxy=$(PROXY) \
	--build-arg HTTP_PROXY=$(PROXY) \
	--build-arg HTTPS_PROXY=$(PROXY) \
	--build-arg no_proxy=$(NO_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY) \
	--build-arg GIT_COMMIT=$(COMMIT)
else
	docker build --force-rm --pull --no-cache \
	https://git.openstack.org/openstack/loci.git \
	--network host \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_REQUIREMENTS) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg PYTHON3=yes \
	--build-arg FROM=${BASE_IMAGE} \
	--build-arg PROJECT=requirements \
	--build-arg PROJECT_REF=${OPENSTACK_VERSION} \
	--build-arg GIT_COMMIT=$(COMMIT)
endif
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif

build_loci_wheels:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
ifeq ($(USE_PROXY), true)
	docker build --force-rm --no-cache \
	-f dockerfiles/ubuntu_Dockerfile \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_LOCI_WHEELS) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg "IMAGE=${IMAGE_REQUIREMENTS}" \
	--build-arg http_proxy=$(PROXY) \
	--build-arg https_proxy=$(PROXY) \
	--build-arg HTTP_PROXY=$(PROXY) \
	--build-arg HTTPS_PROXY=$(PROXY) \
	--build-arg no_proxy=$(NO_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY) \
	--build-arg GIT_COMMIT=$(COMMIT) dockerfiles/
else
	docker build --force-rm --no-cache \
	-f dockerfiles/ubuntu_Dockerfile \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_LOCI_WHEELS) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg "IMAGE=${IMAGE_REQUIREMENTS}" \
	--build-arg GIT_COMMIT=$(COMMIT) dockerfiles/
endif
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif

run_wheel_srvr:
	docker run -d -p 0.0.0.0:8080:80 $(IMAGE_LOCI_WHEELS)

build_ironic:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
ifeq ($(USE_PROXY), true)
	http_proxy=$(PROXY) https_proxy=$(PROXY) \
	HTTP_PROXY=$(PROXY) HTTPS_PROXY=$(PROXY) \
	no_proxy=$(NO_PROXY) NO_PROXY=$(NO_PROXY) \
	docker build --force-rm --pull --no-cache \
	https://git.openstack.org/openstack/loci.git \
	--network host \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_IRONIC) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg PYTHON3=yes \
	--build-arg FROM=${BASE_IMAGE} \
	--build-arg PROJECT=ironic \
	--build-arg PROJECT_REF=${OPENSTACK_VERSION} \
	--build-arg WHEELS=http://172.17.0.1:8080/wheels.tar.gz \
	--build-arg PROFILES=${ironic_profiles} \
	--build-arg PIP_PACKAGES=${ironic_pip_packages} \
	--build-arg DIST_PACKAGES=${ironic_dist_packages} \
	--build-arg http_proxy=$(PROXY) \
	--build-arg https_proxy=$(PROXY) \
	--build-arg HTTP_PROXY=$(PROXY) \
	--build-arg HTTPS_PROXY=$(PROXY) \
	--build-arg no_proxy=$(NO_PROXY) \
	--build-arg NO_PROXY=$(NO_PROXY) \
	--build-arg GIT_COMMIT=$(COMMIT)
else
	docker build --force-rm --pull --no-cache \
	https://git.openstack.org/openstack/loci.git \
	--network host \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE_IRONIC) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg PYTHON3=yes \
	--build-arg FROM=${BASE_IMAGE} \
	--build-arg PROJECT=ironic \
	--build-arg PROJECT_REF=${OPENSTACK_VERSION} \
	--build-arg WHEELS=http://172.17.0.1:8080/wheels.tar.gz \
	--build-arg PROFILES=${ironic_profiles} \
	--build-arg PIP_PACKAGES=${ironic_pip_packages} \
	--build-arg DIST_PACKAGES=${ironic_dist_packages} \
	--build-arg GIT_COMMIT=$(COMMIT)
endif
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif
ifeq ($(PUSH_IMAGE), true)
	docker push $(IMAGE_IRONIC)
endif

clean:
ifeq ($(IMAGE_ID), none)
	if [[ -s $(BUILD_DIR)/image_id ]]; \
	then \
	docker rmi $$(cat $(BUILD_DIR)/image_id); \
	fi
endif
	rm -rf $(BUILD_DIR)

# style checks
lint: test-shellcheck

tests: lint unit_tests

test-shellcheck: $(SH_TO_CHECK)

unit_tests:
	echo TODO

$(SH_TO_CHECK):
	docker run --rm -v $(shell pwd):/mnt \
	nlknguyen/alpine-shellcheck -x /mnt/$(@)

.PHONY: test clean $(SH_TO_CHECK) test-shellcheck tests lint build_requirements \
  build_loci_wheels run_wheel_srvr build_ironic all build_docs docs check-docker images
