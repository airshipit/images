#!/bin/bash

# set -xe

if [[ $# < 5 ]]; then
  echo "usage:"
  echo "  $0 \\\n"
  echo "     <charts filename> \\\n"
  echo "     <image name> \\\n"
  echo "     <image uri> \\\n"
  echo "     <label> \\\n"
  echo "     <build dir> \\\n"
  echo "     <use proxy? true|false> \\\n"
  echo "     [<proxy> <no-proxy>] \\\n"
  exit 1
fi

CHARTS=$1
IMAGE_NAME=$2
IMAGE_URI=$3
LABEL=$4
BUILD_DIR=$5
USE_PROXY=$6
COMMIT=$(git rev-parse HEAD)

echo "Building the Docker image = ${IMAGE}"
echo "  CHARTS=$CHARTS"
echo "  IMAGE_NAME=$IMAGE_NAME"
echo "  IMAGE_URI=$IMAGE_URI"
echo "  LABEL=$LABEL"
echo "  BUILD_DIR=$BUILD_DIR"
echo "  COMMIT=$COMMIT"
echo "  USE_PROXY=$USE_PROXY"

if [ $USE_PROXY == "true" ]; then
PROXY=$8
NO_PROXY=$9

echo "Building Docker image ${IMAGE} with PROXY"
docker build . \
	--iidfile ${BUILD_DIR}/image_id \
	--tag ${IMAGE_URI} \
	--label ${LABEL} \
	--label "org.opencontainers.image.revision=${COMMIT}" \
	--label "org.opencontainers.image.created=\
	$(date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=${IMAGE_NAME}" \
	--force-rm=true \
	--build-arg "CHARTS=\"$(cat "${CHARTS}")\"" \
	--build-arg http_proxy=${PROXY} \
	--build-arg https_proxy=${PROXY} \
	--build-arg HTTP_PROXY=${PROXY} \
	--build-arg HTTPS_PROXY=${PROXY} \
	--build-arg no_proxy=${NO_PROXY} \
	--build-arg NO_PROXY=${NO_PROXY} \
	--build-arg GIT_COMMIT=${COMMIT}
else
echo "Building Docker image ${IMAGE} without PROXY"
docker build . \
	--iidfile ${BUILD_DIR}/image_id \
	--tag ${IMAGE_URI} \
	--label ${LABEL} \
	--label "org.opencontainers.image.revision=${COMMIT}" \
	--label "org.opencontainers.image.created=\
	$(date --rfc-3339=seconds --utc)" \
	--label "org.opencontainers.image.title=${IMAGE_NAME}" \
	--force-rm=true \
    --build-arg "CHARTS=\"$(cat "${CHARTS}")\"" \
	--build-arg GIT_COMMIT=${COMMIT}
fi