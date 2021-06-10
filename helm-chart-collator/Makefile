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
BUILD_DIR         ?= build
PUSH_IMAGE        ?= false
IMAGE_ID          ?= none
COMMIT            ?= $(shell git rev-parse HEAD)
LABEL             ?= org.airshipit.build=community
IMAGE_NAME        ?= helm-chart-collator
DOCKER_REGISTRY   ?= quay.io
IMAGE_PREFIX      ?= airshipit
IMAGE_TAG         ?= latest
DISTRO            ?= debian_stable
CHARTS            ?= config/charts.yaml
IMAGE             := ${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}
SH_TO_CHECK       := $(wildcard files/*.sh )
PROXY             ?= http://proxy.foo.com:8000
NO_PROXY          ?= localhost,127.0.0.1,.svc.cluster.local
USE_PROXY         ?= false

all: lint images

check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi

images: check-docker build_collator

docs: clean build_docs

build_docs:
	echo TODO

run_images: run_collator

run_collator: $(BUILD_DIR)/output-metadata.yaml
	echo OK
	#TODO consistance test

$(BUILD_DIR)/output-metadata.yaml: $(BUILD_DIR)/image_id
ifeq ($(USE_PROXY), true)
docker run --rm -it -p 8080:8080 tester
	docker run \
	--rm  \
	-e http_proxy=$(PROXY) \
	-e https_proxy=$(PROXY) \
	-e HTTP_PROXY=$(PROXY) \
	-e HTTPS_PROXY=$(PROXY) \
	-e no_proxy=$(NO_PROXY) \
	-e NO_PROXY=$(NO_PROXY) \
	$(shell cat $(BUILD_DIR)/image_id)
else
	docker run \
	--rm  \
	$(shell cat $(BUILD_DIR)/image_id)
endif

$(BUILD_DIR)/image_id: build_collator

build_collator:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
ifeq ($(USE_PROXY), true)
	./build-image-make.sh \
	        $(CHARTS) \
		$(IMAGE_NAME) \
		$(IMAGE) \
		$(LABEL) \
		$(BUILD_DIR) \
		$(USE_PROXY) \
		$(PROXY) \
		$(NO_PROXY)
else
	./build-image-make.sh \
	        $(CHARTS) \
		$(IMAGE_NAME) \
		$(IMAGE) \
		$(LABEL) \
		$(BUILD_DIR) \
		$(USE_PROXY)
endif
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif
ifeq ($(PUSH_IMAGE), true)
	docker push $(IMAGE)
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
	echo "TODO"

tests: lint unit_tests

test-shellcheck: $(SH_TO_CHECK)

unit_tests:
	echo TODO

$(SH_TO_CHECK):
	docker run --rm -v $(shell pwd):/mnt \
	nlknguyen/alpine-shellcheck -x /mnt/$(@)

.PHONY: test clean $(SH_TO_CHECK) test-shellcheck tests lint build_collator \
  run_collator run_images all build_docs docs check-docker images
