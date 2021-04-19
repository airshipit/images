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
IMAGE_NAME        ?= vino-reverse-proxy
DOCKER_REGISTRY   ?= quay.io
IMAGE_PREFIX      ?= airshipit
IMAGE_TAG         ?= latest
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

images: check-docker build_vino-reverse-proxy

docs: clean build_docs

build_docs:
	echo TODO

run_images: run_vino-reverse-proxy

run_vino-reverse-proxy:
	echo TODO

build_vino-reverse-proxy:
	mkdir -p $(BUILD_DIR)
ifeq ($(IMAGE_ID), none)
ifeq ($(USE_PROXY), true)
	docker build . \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE) \
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
	--build-arg GIT_COMMIT=$(COMMIT)
else
	docker build . \
	--iidfile $(BUILD_DIR)/image_id \
	--tag $(IMAGE) \
	--label $(LABEL) \
	--label "org.opencontainers.image.revision=$(COMMIT)" \
	--label "org.opencontainers.image.created=\
	$(shell date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=$(IMAGE_NAME)" \
	--build-arg GIT_COMMIT=$(COMMIT)
endif
else
	echo $(IMAGE_ID) > $(BUILD_DIR)/image_id
endif
# push image
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

tests: lint unit_tests run_vino-reverse-proxy

test-shellcheck: $(SH_TO_CHECK)

unit_tests:
	echo TODO

$(SH_TO_CHECK):
	docker run --rm -v $(shell pwd):/mnt \
	nlknguyen/alpine-shellcheck -x /mnt/$(@)

.PHONY: test clean $(SH_TO_CHECK) test-shellcheck tests lint build_vino-reverse-proxy \
  run_vino-reverse-proxy run_images all build_docs docs check-docker images
