#!/usr/bin/python
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# generate_baremetal_macs method ripped from
# openstack/tripleo-incubator/scripts/configure-vm

import math
import random
import sys
import fnmatch
import os
from itertools import chain
import json

DOCUMENTATION = '''
---
module: core_allocation
version_added: "1.0"
short_description: Allocate numa aligned cores for libvirt domains and track allocations
description:
   - Generate numa aligned cores for libvirt domains and track allocations
'''

PATH_SYS_DEVICES_NODE = "/sys/devices/system/node"

def _parse_range(rng):
    parts = rng.split('-')
    if 1 > len(parts) > 2:
        raise ValueError("Bad range: '%s'" % (rng,))
    parts = [int(i) for i in parts]
    start = parts[0]
    end = start if len(parts) == 1 else parts[1]
    if start > end:
        end, start = start, end
    return range(start, end + 1)

def _parse_range_list(rngs):
    return sorted(set(chain(*[_parse_range(rng) for rng in rngs.split(',')])))

def get_numa_cores():
    """Return cores as a dict of numas each with their expanded core lists"""
    numa_core_dict = {}
    for root, dir, files in os.walk(PATH_SYS_DEVICES_NODE):
        for numa in fnmatch.filter(dir, "node*"):
            numa_path = os.path.join(PATH_SYS_DEVICES_NODE, numa)
            cpulist = os.path.join(numa_path, "cpulist")
            with open(cpulist, 'r') as f:
                parsed_range_list = _parse_range_list(f.read())
                numa_core_dict[numa] = parsed_range_list
    return numa_core_dict

def allocate_cores(nodes, flavors, exclude_cpu):
    """Return"""

    core_state = {}

    try:
        f = open('/etc/libvirt/vino-cores.json', 'r')
        core_state = json.loads(f.read())
    except:
        pass

    # instantiate initial inventory - we don't support the inventory
    # changing (e.g. adding cores)
    if 'inventory' not in core_state:
        core_state['inventory'] = get_numa_cores()

    # explode exclude cpu list - we don't support adjusting this after-the-fact
    # right now
    if 'exclude' not in core_state:
        exclude_core_list = _parse_range_list(exclude_cpu)
        core_state['exclude'] = exclude_core_list

    # reduce inventory by exclude
    if 'available' not in core_state:
        core_state['available'] = {}
        for numa in core_state['inventory'].keys():
            numa_available = [x for x in core_state['inventory'][numa] if x not in core_state['exclude']]
            core_state['available'][numa] = numa_available

    if 'assignments' not in core_state:
        core_state['assignments'] = {}

    # walk the nodes, consuming inventory or discovering previous allocations
    # address the case where previous != desired - delete previous, re-run
    for node in nodes:

        flavor = node['bmhLabels']['airshipit.org/k8s-role']
        vcpus = flavors[flavor]['vcpus']

        for num_node in range(0, node['count']):

            # generate a unique name such as master-0, master-1
            node_name = node['name'] + '-' + str(num_node)

            # extract the core count
            core_count = int(vcpus)

            # discover any previous allocation
            if 'assignments' in core_state:
                if node_name in core_state['assignments']:
                    if len(core_state['assignments'][node_name]) == core_count:
                        continue
                    else:
                        # TODO: support releasing the cores and adding them back
                        # to available
                        raise Exception("Existing assignment exists for node %s but does not match current core count needed" % node_name)

            # allocate the cores
            allocated=False
            for numa in core_state['available']:
                if core_count <= len(core_state['available'][numa]):
                    allocated=True
                    cores_to_use = core_state['available'][numa][:core_count]
                    core_state['assignments'][node_name] = cores_to_use
                    core_state['available'][numa] = core_state['available'][numa][core_count:]
                    break
                else:
                    continue
            if not allocated:
                raise Exception("Unable to find sufficient cores (%s) for node %s (available was %r)" % (core_count, node_name, core_state['available']))

    # return a dict of nodes: cores
    # or error if insufficient
    with open('/etc/libvirt/vino-cores.json', 'w') as f:
        f.write(json.dumps(core_state))

    return core_state['assignments']


def main():
    module = AnsibleModule(
        argument_spec=dict(
            nodes=dict(required=True, type='list'),
            flavors=dict(required=True, type='dict'),
            exclude_cpu=dict(required=True, type='str')
        )
    )
    result = allocate_cores(module.params["nodes"],
                            module.params["flavors"],
                            module.params["exclude_cpu"])
    module.exit_json(**result)

# see http://docs.ansible.com/developing_modules.html#common-module-boilerplate
from ansible.module_utils.basic import AnsibleModule  # noqa


if __name__ == '__main__':
    main()