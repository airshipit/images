#!/bin/bash

set -xe

if [[ $# != 1 ]]; then
  printf "usage: $0 <charts file>\n"
  exit 1
fi

IMAGE_NAME="${IMAGE_NAME:-helm-chart-collator}"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-quay.io}"
IMAGE_PREFIX="${IMAGE_PREFIX:-airshipit}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

image=${DOCKER_REGISTRY}/${IMAGE_PREFIX}/${IMAGE_NAME}:${IMAGE_TAG}
echo "Building the ${image}"
docker build . -t $image --build-arg "CHARTS=$(cat "$1")"
