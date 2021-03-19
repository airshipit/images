#!/bin/bash

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

build_dir=assets/playbooks/build
osconfig_build_dir=$(basename $build_dir)
host_mount_directory="${1:-$BASEDIR/../manifests}"
workdir="$(realpath ${host_mount_directory})"

install_pkg(){
    dpkg -l $1 2> /dev/null | grep ^ii > /dev/null || sudo -E apt-get -y install $1
}

setup_chroot(){
    # Idempotently setup chroot mounts
    mkdir -p $build_dir
    mkdir -p $build_dir/sys
    mountpoint $build_dir/sys > /dev/null || sudo mount -t sysfs /sys $build_dir/sys
    if [ -d /sys/firmware/efi ]; then
        mountpoint $build_dir/sys/firmware/efi > /dev/null || sudo mount -o bind /sys/firmware/efi $build_dir/sys/firmware/efi
    fi
    mkdir -p $build_dir/proc
    mountpoint $build_dir/proc > /dev/null || sudo mount -t proc /proc $build_dir/proc
    mkdir -p $build_dir/dev
    mountpoint $build_dir/dev > /dev/null || sudo mount -o bind /dev $build_dir/dev
    mountpoint $build_dir/dev/pts > /dev/null || sudo mount -t devpts /dev/pts $build_dir/dev/pts
    mkdir -p $osconfig_build_dir
    mountpoint $osconfig_build_dir > /dev/null || sudo mount -o bind $build_dir $osconfig_build_dir
    if [ -d "/run/systemd/resolve" ]; then
      mkdir -p $build_dir/run/systemd/resolve
      mountpoint $build_dir/run/systemd/resolve > /dev/null || sudo mount -o bind /run/systemd/resolve $build_dir/run/systemd/resolve
    fi
}

umount_helper(){
    if [[ -d "$1" ]] && mountpoint "$1" > /dev/null; then
        # if umount fails in first attempt, we try to use lazy umount
        sudo umount "$1" || sudo umount -l "$1"
    fi
}

umount_chroot(){
    # Idempotently teardown chroot mounts
    umount_helper $build_dir/dev/pts
    umount_helper $build_dir/dev
    if [[ -d /sys/firmware/efi ]]; then
	umount_helper $build_dir/sys/firmware/efi
    fi
    umount_helper $build_dir/sys
    umount_helper $build_dir/proc
    umount_helper $osconfig_build_dir
    if [ -d "/run/systemd/resolve" ]; then
      umount_helper $build_dir/run/systemd/resolve
    fi
}

# Install pre-requisites
if [ ! -f /var/lib/apt/periodic/update-success-stamp ] || \
     sudo find /var/lib/apt/periodic/update-success-stamp -mtime +1 | grep update-success-stamp; then
     sudo -E apt -y update
fi

install_pkg efivar
# required for building UEFI image
sudo -E modprobe efivars
type docker >& /dev/null || (echo "Error: You do not have docker installed in your environment." && exit 1)
sudo docker version | grep Community >& /dev/null || (echo "Error: Could not find Community version of docker" && \
	echo "You must uninstall docker.io and install docker-ce. For instructions, see https://docs.docker.com/engine/install/ubuntu/" && \
	exit 1)
install_pkg equivs
install_pkg ca-certificates
install_pkg build-essential
install_pkg gnupg2
install_pkg multistrap
install_pkg curl
install_pkg grub-common
install_pkg grub2-common
install_pkg grub-pc-bin
install_pkg grub-efi-amd64-signed
install_pkg dosfstools
install_pkg mtools
install_pkg squashfs-tools
install_pkg python3-minimal
install_pkg python3-pip
install_pkg python3-apt
install_pkg python3-setuptools
sudo -E pip3 install --upgrade pip
pip3 show wheel >& /dev/null || sudo -E pip3 install --upgrade wheel
pip3 show ansible >& /dev/null || sudo -E pip3 install --upgrade ansible

if [[ $1 = clean ]]; then
    umount_chroot
    if [ -f $build_dir/etc/kernel/postinst.d/kdump-tools ]; then
      sudo chattr -i $build_dir/etc/kernel/postinst.d/kdump-tools
    fi
    if [[ -d $build_dir ]]; then
        sudo rm -rf $build_dir
    fi
    if [[ -d $osconfig_build_dir ]]; then
        sudo rm -rf $osconfig_build_dir
    fi
    exit 0
elif [[ $1 = umount ]]; then
    umount_chroot
    exit 0
elif [[ $1 = mount ]]; then
    setup_chroot
    exit 0
fi

setup_chroot

# Archive a copy of the ansible used to generate the image in the image itself
mkdir -p $build_dir/opt/assets/playbooks/roles
cp assets/playbooks/inventory.yaml $build_dir/opt/assets/playbooks/inventory.yaml
cp assets/playbooks/base-chroot.yaml $build_dir/opt/assets/playbooks/base-chroot.yaml
cp -r assets/playbooks/roles/multistrap $build_dir/opt/assets/playbooks/roles
# Run multistrap
if [ -z $SKIP_MULTI_ROLE ]; then
  sudo -E ansible-playbook -i assets/playbooks/inventory.yaml assets/playbooks/base-chroot.yaml -vv
fi

cp assets/playbooks/base-osconfig.yaml $build_dir/opt/assets/playbooks/base-osconfig.yaml
cp -r assets/playbooks/roles/osconfig $build_dir/opt/assets/playbooks/roles
if [ -d $build_dir/config ]; then
  sudo rm -r $build_dir/config
fi
mkdir -p $build_dir/config
cp -r $workdir/scripts $build_dir/config/
if [ -z "$SKIP_OSCONFIG_ROLE" ]; then
  sudo -E ansible-playbook -i assets/playbooks/inventory.yaml assets/playbooks/base-osconfig.yaml --extra-vars "run_context=common" -vv
fi

umount_chroot

cp assets/playbooks/base-livecdcontent.yaml $build_dir/opt/assets/playbooks/base-livecdcontent.yaml
cp -r assets/playbooks/roles/livecdcontent $build_dir/opt/assets/playbooks/roles
if [ -z "$SKIP_LIVECDCONTENT_ROLE" ]; then
  sudo -E ansible-playbook -i assets/playbooks/inventory.yaml assets/playbooks/base-livecdcontent.yaml -vv
fi

cp assets/playbooks/iso.yaml $build_dir/opt/assets/playbooks/iso.yaml
cp -r assets/playbooks/roles/iso $build_dir/opt/assets/playbooks/roles
cp assets/playbooks/qcow.yaml $build_dir/opt/assets/playbooks/qcow.yaml
cp -r assets/playbooks/roles/qcow $build_dir/opt/assets/playbooks/roles

if [ ! -e $build_dir/dev/random ]; then
    sudo -E mknod $build_dir/dev/random c 1 8
    sudo -E chmod 640 $build_dir/dev/random
    sudo -E chown 0:0 $build_dir/dev/random
fi
if [ ! -e $build_dir/dev/urandom ]; then
    sudo -E mknod $build_dir/dev/urandom c 1 9
    sudo -E chmod 640 $build_Dir/dev/urandom
    sudo -E chown 0:0 $build_Dir/dev/urandom
fi
if [ -f $build_dir/dev/null ]; then
    sudo rm -f $build_dir/dev/null
fi
if [ ! -e $build_dir/dev/null ]; then
    sudo -E mknod $build_dir/dev/null c 1 3
    sudo -E chmod 666 $build_dir/dev/null
    sudo -E chown 0:0 $build_dir/dev/null
fi

