#!/bin/bash
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.
set -ex


if [ -n "$(cat /proc/*/comm 2>/dev/null | grep -w libvirtd)" ]; then
  set +x
  for proc in $(ls /proc/*/comm 2>/dev/null); do
    if [ "x$(cat $proc 2>/dev/null | grep -w libvirtd)" == "xlibvirtd" ]; then
      set -x
      libvirtpid=$(echo $proc | cut -f 3 -d '/')
      echo "WARNING: libvirtd daemon already running on host" 1>&2
      echo "$(cat "/proc/${libvirtpid}/status" 2>/dev/null | grep State)" 1>&2
      kill -9 "$libvirtpid" || true
      set +x
    fi
  done
  set -x
fi

rm -f /var/run/libvirtd.pid

if [[ -c /dev/kvm ]]; then
    chmod 660 /dev/kvm
    chown root:kvm /dev/kvm
fi

CGROUPS=""
for CGROUP in cpu rdma hugetlb; do
  if [ -d /sys/fs/cgroup/${CGROUP} ]; then
    CGROUPS+="${CGROUP},"
  fi
done
cgcreate -g ${CGROUPS%,}:/osh-libvirt

hp_count="$(cat /proc/meminfo | grep HugePages_Total | tr -cd '[:digit:]')"
if [ 0"$hp_count" -gt 0 ]; then

  echo "INFO: Detected hugepage count of '$hp_count'. Enabling hugepage settings for libvirt/qemu."

  if [ -n "$(grep KVM_HUGEPAGES=0 /etc/default/qemu-kvm)" ]; then
    sed -i 's/.*KVM_HUGEPAGES=0.*/KVM_HUGEPAGES=1/g' /etc/default/qemu-kvm
  else
    echo KVM_HUGEPAGES=1 >> /etc/default/qemu-kvm
  fi
fi
  exec cgexec -g ${CGROUPS%,}:/osh-libvirt systemd-run --scope --slice=system libvirtd

