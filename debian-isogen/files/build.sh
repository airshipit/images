#!/bin/bash
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

BASEDIR="$(dirname "$(realpath "$0")")"
# shellcheck source=files/functions.sh
source "${BASEDIR}/functions.sh"

set -xe

_check_input_data_set_vars

_debootstrap

chroot "${CHROOT}" < "${BASEDIR}/packages_install.sh"

_use_ubuntu_net_device_names

mkdir -p "${CLOUD_DATA_LATEST}"
cp "${BASEDIR}/meta_data.json" "${CLOUD_DATA_LATEST}"
cp "${USER_DATA}" "${CLOUD_DATA_LATEST}/user_data"
yq r -j "${NET_CONFIG}" > "${CLOUD_DATA_LATEST}/network_data.json"
echo "datasource_list: [ ConfigDrive, None ]" > \
    "${CHROOT}/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg"

_make_kernel
_grub_install
_make_iso

OUTPUT="$(yq r "${BUILDER_CONFIG}" builder.outputMetadataFileName)"
HOST_PATH="${ADDR[0]}"
_make_metadata "${VOLUME}/${OUTPUT}" "${HOST_PATH}"
