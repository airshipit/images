SHELL := /bin/bash

PUSH_IMAGE        ?= false

DOCKER_MAKE_TARGET  := build

# docker image options
DOCKER_REGISTRY     ?= quay.io
DOCKER_FORCE_CLEAN  ?= true
DOCKER_IMAGE_NAME   ?= capo-ephemeral
DOCKER_IMAGE_PREFIX ?= airshipit
DOCKER_IMAGE_TAG    ?= latest
DOCKER_IMAGE        ?= $(DOCKER_REGISTRY)/$(DOCKER_IMAGE_PREFIX)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)
DOCKER_TARGET_STAGE ?= release
CONTAINER_TEMP = capo-ephemeral-temp

.PHONY: all
all: build docker

.PHONY: images
images: build docker

.PHONY: build
build: main.go go.mod go.sum config/openstack_cluster.go config/openstack_config.go Dockerfile
	@docker build --target builder --network=host \
	    --build-arg MAKE_TARGET=$(DOCKER_MAKE_TARGET) \
		--tag $(DOCKER_IMAGE) .
	docker run --name $(CONTAINER_TEMP) $(DOCKER_IMAGE) /bin/true
	docker cp $(CONTAINER_TEMP):/home/build/capo-ephemeral .

.PHONY: docker
docker: capo-ephemeral resource/create-k8s-cluster.sh resource/delete-k8s-cluster.sh resource/user-data.sh resource/help.txt Dockerfile
	@docker build . --network=host \
	    --build-arg MAKE_TARGET=$(DOCKER_MAKE_TARGET) \
	    --tag $(DOCKER_IMAGE) \
	    --force-rm=$(DOCKER_FORCE_CLEAN)

ifeq ($(PUSH_IMAGE), true)
	docker push $(DOCKER_IMAGE)
endif

.PHONY: clean
clean:
	@rm capo-ephemeral

.PHONY: lint
lint:
	@echo TODO

# style checks
.PHONY: tests
tests: images
	    sudo rm -f $(HELP_FILE)
	    cp openstack-config.yaml /tmp
	    docker run -v /tmp:/kube --env-file bootstrap-env.list --name capo-bootstrap-test $(DOCKER_IMAGE)