SHELL := /bin/bash
PUSH_IMAGE          ?= false
GIT_VERSION         ?= v0.1.0
GIT_MODULE          ?= opendev.org/airship/airshipctl/pkg/version

GO_FLAGS            := -ldflags '-extldflags "-static"' -tags=netgo
GO_FLAGS            += -ldflags "-X ${GIT_MODULE}.gitVersion=${GIT_VERSION}"

DOCKER_MAKE_TARGET  := build

# docker image options
DOCKER_REGISTRY     ?= quay.io
DOCKER_FORCE_CLEAN  ?= true
DOCKER_IMAGE_NAME   ?= capg-bootstrap
DOCKER_IMAGE_PREFIX ?= airshipit
DOCKER_IMAGE_TAG    ?= latest
DOCKER_IMAGE        ?= $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
DOCKER_TARGET_STAGE ?= release

PATH += :/usr/local/go/bin
HELP_FILE ?= /tmp/help.txt
ORIGINAL_HELP_FILE = ./assets/help.txt

.PHONY: all
all: images

.PHONY: images
images: Dockerfile \
		main.go \
		config/gke_cluster.go \
		config/gcp_cluster.go \
		config/gcp_config.go \
		assets/help.txt
	@docker build . --network=host \
	    --build-arg MAKE_TARGET=$(DOCKER_MAKE_TARGET) \
	    --tag $(DOCKER_IMAGE) \
	    --force-rm=$(DOCKER_FORCE_CLEAN)
ifeq ($(PUSH_IMAGE), true)
	docker push $(DOCKER_IMAGE)
endif

.PHONY: clean
clean:
	@docker image rm $(DOCKER_IMAGE)

.PHONY: lint
lint:
	@echo TODO

# style checks
.PHONY: tests
tests: images
	if [ -f $(HELP_FILE) ]; then sudo rm $(HELP_FILE); fi
	cp gcp-config.yaml /tmp
	docker run -v /tmp:/kube --env-file bootstrap-env.list --name capg-test $(DOCKER_IMAGE)
	cmp $(HELP_FILE) $(ORIGINAL_HELP_FILE)
