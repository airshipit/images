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

echo ""
echo "Checking Environment Variables used by the Bootstrap Container ..."

if [[ -z "$OS_MACHINE_FLAVOR" ]]; then
    echo "Assigning default value for OS_MACHINE_FLAVOR"
    export OS_MACHINE_FLAVOR="ds2G"
fi

if [[ -z "$OS_KUBECONFIG_FILE" ]]; then
    echo "Assigning default value for OS_KUBECONFIG_FILE"
    export OS_KUBECONFIG_FILE="kubeconfig"
fi
if [[ -z "$OS_SECURITY_GROUP" ]]; then
    echo "Assigning default value for OS_SECURITY_GROUP"
    export OS_SECURITY_GROUP="bootstrap-mgmt-sec-grp"
fi

cp /kube/"$OS_CREDENTIAL_FILE" ~

echo "OS_CLOUD = $OS_CLOUD"
echo "OS_CREDENTIAL_FILE = $OS_CREDENTIAL_FILE"
echo "OS_MACHINE_FLAVOR = $OS_MACHINE_FLAVOR"
echo "OS_KUBECONFIG_FILE = $OS_KUBECONFIG_FILE"
echo "OS_SECURITY_GROUP = $OS_SECURITY_GROUP"
echo ""
echo ""


echo "creating envs"

export SECURITY_GROUP=$OS_SECURITY_GROUP
export CAPI_VM="bootstrap-k8s"

export OS_USERNAME=admin

echo "listing all active images"
openstack image list

echo "SECURITY_GROUP = $SECURITY_GROUP"
echo "VM NAME = $CAPI_VM"

#echo "creating security group"
openstack security group create --project demo --project-domain Default $SECURITY_GROUP

#echo "adding rules to the security group"
openstack security group rule create $SECURITY_GROUP --protocol tcp --remote-ip 0.0.0.0/0

openstack security group rule create $SECURITY_GROUP --protocol tcp --dst-port 10248:10252 --remote-ip 0.0.0.0/0

export PRIVATE_NETWORK_ID=$(openstack network show private | grep "\<id\>" | awk '{print $4}' )
export K8S_IMAGE_ID=$(openstack image list | grep "ubuntu-k8s" | awk '{print $2}' )

echo "PRIVATE_NW_ID = $PRIVATE_NETWORK_ID"
echo "K8S_IMAGE = $K8S_IMAGE_ID"

#Generate ssh key pair without being prompted for pass phrase
ssh-keygen -f ~/.ssh/id_rsa -t rsa -N ''

echo "printing public key"
echo $(cat ~/.ssh/id_rsa.pub)
export SSH_KEY_PUB=$(cat ~/.ssh/id_rsa.pub)
echo $SSH_KEY_PUB > stack.pub

openstack keypair delete stack

echo "creating openstack key pair"
openstack keypair create --public-key stack.pub stack

echo "************** listing key pairs ***************"
openstack keypair list

export FLOATING_IP_ADDRESS=${FLOATING_IP_ADDRESS:-172.24.4.199}

echo "Add floating IP to public network"
openstack floating ip create public --floating-ip-address $FLOATING_IP_ADDRESS

echo "creating vm for spinning up ephemeral kubernetes cluster"
openstack server create --image $K8S_IMAGE_ID --flavor $OS_MACHINE_FLAVOR --security-group $SECURITY_GROUP --nic net-id=$PRIVATE_NETWORK_ID \
        --key-name stack --user-data user-data.sh $CAPI_VM --wait

echo "associating floating ip with vm"
openstack server add floating ip $CAPI_VM $FLOATING_IP_ADDRESS

echo "waiting for kubernets cluster to be up"

#echo "check if kube config is ready on remote vm"

N=0
MAX_RETRY=30
DELAY=60

until [ "$N" -ge ${MAX_RETRY} ]
do
  if ssh -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$FLOATING_IP_ADDRESS '[ -d /home/ubuntu/.kube/ ]'; then
    printf "kube config is available\n"
    break
  else
    printf "Kube config does not exist, or still being created\n"
    N=$((N+1))
    echo "$N: Retry to check if kubeconfig exists"
    sleep ${DELAY}
  fi
done

echo "copying the kubeconfig of ephemeral cluster to container host"
scp -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa ubuntu@$FLOATING_IP_ADDRESS:/home/ubuntu/.kube/config /kube/$OS_KUBECONFIG_FILE

chmod +rw /kube/$OS_KUBECONFIG_FILE

echo "done copying kubeconfig file"

echo "*************** done ***************"