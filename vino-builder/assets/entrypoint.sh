#!/bin/bash

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

set -ex

TIMEOUT=300
while [[ ! -e /var/run/libvirt/libvirt-sock ]]; do
  if [[ ${TIMEOUT} -gt 0 ]]; then
    let TIMEOUT-=1
    echo "Waiting for libvirt socket at /var/run/libvirt/libvirt-sock"
    sleep 1
  else
    echo "ERROR: libvirt did not start in time (socket missing) /var/run/libvirt/libvirt-sock"
    exit 1
  fi
done

ansible-playbook -v -e @/var/lib/vino-builder/vino-builder-config.yaml /playbooks/vino-builder.yaml