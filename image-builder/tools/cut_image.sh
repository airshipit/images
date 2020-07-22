#!/bin/bash
set -ex

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

# Whether to build an 'iso' or 'qcow'
build_type="${1:-qcow}"
# The host mount to use to exchange data with this container
host_mount_directory="${2:-$BASEDIR/../examples}"
# Docker image to use when launching this container
image="${3:-port/image-builder:latest-ubuntu_focal}"
# Libvirt instance name to use for a new libvirt XML definition that
# will be created to reference the newly created ISO or QCOW2 image.
img_alias="${4:-port-image-builder-latest-ubuntu_focal-$build_type}"
# Whether or not to build the image with UEFI support.
# NOTE: Machines that are not booted with UEFI will be unable to create
# UEFI images.
uefi_boot="$5"
# proxy to use, if applicable
proxy="$6"
# noproxy to use, if applicable
noproxy="$7"

if [ -n "$proxy" ]; then
  export http_proxy=$proxy
  export https_proxy=$proxy
  export HTTP_PROXY=$proxy
  export HTTPS_PROXY=$proxy
fi

if [ -n "$noproxy" ]; then
  export no_proxy=$noproxy
  export NO_PROXY=$noproxy
fi

if [ -n "$uefi_boot" ]; then
  uefi_mount='--volume /sys/firmware/efi:/sys/firmware/efi:rw'
fi

workdir="$(realpath ${host_mount_directory})"

if [[ $build_type = iso ]]; then
  sudo -E docker run -t --rm \
   --volume $workdir:/config \
   --env BUILDER_CONFIG=/config/${build_type}.yaml \
   --env IMAGE_TYPE="iso" \
   --env http_proxy=$proxy \
   --env https_proxy=$proxy \
   --env HTTP_PROXY=$proxy \
   --env HTTPS_PROXY=$proxy \
   --env no_proxy=$noproxy \
   --env NO_PROXY=$noproxy \
   ${image}
  disk1="--disk path=${workdir}/ephemeral.iso,device=cdrom"
elif [[ $build_type == qcow ]]; then
  sudo -E modprobe nbd
  sudo -E docker run -t --rm \
   --privileged \
   --volume /dev:/dev:rw  \
   --volume /dev/pts:/dev/pts:rw \
   --volume /proc:/proc:rw \
   --volume /sys:/sys:rw \
   --volume /lib/modules:/lib/modules:rw \
   --volume $workdir:/config \
   ${uefi_mount} \
   --env BUILDER_CONFIG=/config/${build_type}.yaml \
   --env IMAGE_TYPE="qcow" \
   --env http_proxy=$proxy \
   --env https_proxy=$proxy \
   --env HTTP_PROXY=$proxy \
   --env HTTPS_PROXY=$proxy \
   --env no_proxy=$noproxy \
   --env NO_PROXY=$noproxy \
   --env uefi_boot=$uefi_boot \
   ${image}
  cloud_init_config_dir='assets/tests/qcow/cloud-init'
  sudo -E cloud-localds -v --network-config="${cloud_init_config_dir}/network-config" "${workdir}/airship-ubuntu_config.iso" "${cloud_init_config_dir}/user-data" "${cloud_init_config_dir}/meta-data"
  disk1="--disk path=${workdir}/control-plane.qcow2"
  disk2="--disk path=${workdir}/airship-ubuntu_config.iso,device=cdrom"
  if [ -n "$uefi_boot" ]; then
    uefi_boot_arg='--boot uefi'
  fi
else
  echo Unknown build type: $build_type, exiting.
  exit 1
fi

imagePath=$(echo $disk1 | cut -d'=' -f2 | cut -d',' -f1)
echo Image successfully written to $imagePath

sudo -E virsh destroy ${img_alias} 2> /dev/null || true
sudo -E virsh undefine ${img_alias} --nvram 2> /dev/null || true

cpu_type=''
kvm-ok >& /dev/null && cpu_type='--cpu host-passthrough' || true

network='--network network=default,mac=52:54:00:6c:99:85'
if ! sudo -E virsh net-list | grep default | grep active > /dev/null; then
  network='--network none'
fi

xml=$(mktemp)
sudo -E virt-install --connect qemu:///system \
 --name ${img_alias} \
 --memory 1536 \
 ${network} \
 ${cpu_type} \
 --vcpus 4 \
 --import \
 ${disk1} \
 ${disk2} \
 ${virt_type} \
 ${uefi_boot_arg} \
 --noautoconsole \
 --graphics vnc,listen=0.0.0.0 \
 --print-xml > $xml
virsh define $xml

echo Virsh definition accepted
echo Image artifact located at $imagePath

