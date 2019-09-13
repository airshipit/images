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

cat "${NET_CONFIG}" >> "${CHROOT}/etc/cloud/cloud.cfg.d/network-config.cfg"
cat "${USER_DATA}" >> "${CHROOT}/etc/cloud/cloud.cfg.d/user-data.cfg"
echo "datasource_list: [ NoCloud, None ]" > \
    "${CHROOT}/etc/cloud/cloud.cfg.d/95_no_cloud_ds.cfg"

_make_kernel
_grub_install
_make_iso

OUTPUT="$(yq r "${BUILDER_CONFIG}" builder.outputMetadataFileName)"
HOST_PATH="${ADDR[0]}"
_make_metadata "${VOLUME}/${OUTPUT}" "${HOST_PATH}"
