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

# Bootstrap Environment Variables MUST be provided when running the Container
echo "Checking that Openstack Cloud Name has been provided ..."
if [[ -z "$OS_CLOUD" ]]; then
    echo "Openstack cloud name MUST be provided."
    exit 1
else
    echo "OS_CLOUD = $OS_CLOUD"
fi

echo "Checking that Openstack Cloud Configuration has been provided ..."
if [[ -z "$OS_CREDENTIAL_FILE" ]]; then
    echo "Openstack Cloud Configuration MUST be provided."
    exit 1
else
    echo "OS_CREDENTIAL_FILE = $OS_CREDENTIAL_FILE"
fi

cp /kube/$OS_CREDENTIAL_FILE ~

echo "deleting the k8s ephemeral cluster"

if [[ -z "$OS_KUBECONFIG_FILE" ]]; then
    echo "Assigning default value for OS_KUBECONFIG_FILE"
    export OS_KUBECONFIG_FILE="kubeconfig"
fi
if [[ -z "$OS_SECURITY_GROUP" ]]; then
    echo "Assigning default value for OS_SECURITY_GROUP"
    export OS_SECURITY_GROUP="bootstrap-mgmt-sec-grp"
fi

export SECURITY_GROUP=$OS_SECURITY_GROUP
export CAPI_VM="bootstrap-k8s"
export FLOATING_IP_ADDRESS=${FLOATING_IP_ADDRESS:-172.24.4.199}
echo "OS_CLOUD = $OS_CLOUD"
echo "OS_CREDENTIAL_FILE = $OS_CREDENTIAL_FILE"
echo "OS_MACHINE_FLAVOR = $OS_MACHINE_FLAVOR"
echo "OS_KUBECONFIG_FILE = $OS_KUBECONFIG_FILE"
echo "OS_SECURITY_GROUP = $OS_SECURITY_GROUP"
echo ""
echo ""

openstack server delete $CAPI_VM --wait

if [ $? -ne 0 ]; then
    echo "*** Failed to delete cluster in VM $CAPI_VM "
    exit 1
fi

echo "K8s cluster deleted successfully in VM $CAPI_VM"

openstack security group delete $SECURITY_GROUP

if [ $? -ne 0 ]; then
    echo "*** Failed to delete security group $SECURITY_GROUP."
    exit 1
fi
echo "Security Group $SECURITY_GROUP is deleted successfully."

openstack floating ip delete $FLOATING_IP_ADDRESS
if [ $? -ne 0 ]; then
    echo "*** Failed to delete floating ip $FLOATING_IP_ADDRESS."
    exit 1
fi
echo "Floating IP $FLOATING_IP is released successfully."

echo "Kubernetes ephemeral cluster on vm $CAPI_VM is deleted successfully."
