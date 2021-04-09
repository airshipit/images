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

READINESS_CHECK_FILE="/tmp/healthy"

## Remove healthy status before starting
[ -f "${READINESS_CHECK_FILE}" ] && rm ${READINESS_CHECK_FILE}

# wait for libvirt socket to be ready
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

# wait for dynamic data to be ready
# data is node-specific, so it will be passed as a node annotations
# of the form
# metadata:
#   annotations:
#     airshipit.org/vino.network-values: |
#       bunch-of-yaml
DYNAMIC_DATA_FILE=/var/lib/vino-builder/dynamic.yaml
TIMEOUT=300
while [[ ${TIMEOUT} -gt 0 ]]; do
  let TIMEOUT-=10
  if [[ ${TIMEOUT} -le 0 ]]; then
    echo "ERROR: vino-builder dynamic data was not ready in time"
    exit 1
  fi
  kubectl get node $HOSTNAME -o=jsonpath="{.metadata.annotations.airshipit\.org/vino\.network-values}" > $DYNAMIC_DATA_FILE
  if [[ -s $DYNAMIC_DATA_FILE ]]; then
    break
  fi
  echo "vino-builder dynamic data not ready yet - sleeping for 10 seconds..."
  sleep 10
done

ansible-playbook -v \
    -e @/var/lib/vino-builder/flavors/flavors.yaml \
    -e @/var/lib/vino-builder/flavor-templates/flavor-templates.yaml \
    -e @/var/lib/vino-builder/network-templates/network-templates.yaml \
    -e @/var/lib/vino-builder/storage-templates/storage-templates.yaml \
    -e @$DYNAMIC_DATA_FILE \
    /playbooks/vino-builder.yaml

touch ${READINESS_CHECK_FILE}

while true; do
  sleep infinity
done