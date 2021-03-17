#!/usr/bin/env bash
set -e

# Default script behavior
#
# BASE_IMAGE represents LOCI's "base" image name.
# Use ubuntu|leap15|centos|debian to build base image from LOCI's Dockerfiles.
: "${BASE_IMAGE:="docker.io/ubuntu:bionic"}"
# Replace with Registry URI with your registry like your
# dockerhub user. Example: "docker.io/openstackhelm"
: "${REGISTRY_URI:="quay.io/airshipit"}"
# The openstack branch to build, if no per project branch is given.
: "${OPENSTACK_VERSION:=stable/victoria}"
# Sepcify OS distribution
: "${DISTRO:="ubuntu_bionic"}"
# extra build arguments for the base image. See loci's dockerfiles for
# arguments that could be used for example.
: "${base_extra_build_args:="--force-rm --pull --no-cache"}"
# Defaults for projects
: "${ironic_profiles:="'fluent ipxe ipmi qemu tftp'"}"
: "${ironic_pip_packages:="pycrypto python-openstackclient sushy"}"
: "${ironic_dist_packages:="ethtool lshw iproute2"}"
# Image tag
if [ -z "${IMAGE_TAG}" ]; then
    IMAGE_TAG="${OPENSTACK_VERSION#*/}-${DISTRO}"
fi

echo "Build Pre-Requirement docker image"
docker build ${base_extra_build_args} \
    https://git.openstack.org/openstack/loci.git \
    --network host \
    --build-arg PYTHON3=yes \
    --build-arg FROM=${BASE_IMAGE} \
    --build-arg PROJECT=requirements \
    --build-arg PROJECT_REF=${OPENSTACK_VERSION} \
    --tag ${REGISTRY_URI}/requirements:${IMAGE_TAG}

echo "Build Container with wheel packages"
docker build --force-rm --no-cache \
    -f dockerfiles/ubuntu_Dockerfile \
    --build-arg "IMAGE=${REGISTRY_URI}/requirements:${IMAGE_TAG}" \
    --tag ${REGISTRY_URI}/loci_wheels:latest dockerfiles/

echo "Host wheel packages in web server"
docker run -d -p 0.0.0.0:8080:80 ${REGISTRY_URI}/loci_wheels:latest

echo "Build ironic image"
docker build ${base_extra_build_args} \
    https://git.openstack.org/openstack/loci.git \
    --network host \
    --build-arg PYTHON3=yes \
    --build-arg FROM=${BASE_IMAGE} \
    --build-arg PROJECT=ironic \
    --build-arg PROJECT_REF=${OPENSTACK_VERSION} \
    --build-arg WHEELS=http://172.17.0.1:8080/wheels.tar.gz \
    --build-arg PROFILES="${ironic_profiles}" \
    --build-arg PIP_PACKAGES="${ironic_pip_packages}" \
    --build-arg DIST_PACKAGES="${ironic_dist_packages}" \
    --tag ${REGISTRY_URI}/ironic:${IMAGE_TAG}
