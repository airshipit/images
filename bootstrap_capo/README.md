# Openstack Bootstrap Container

This project contains the Go application as well as the shell scripts and configuration files for
implementing the Openstack Bootstrap container.

The Openstack Bootstrap container is responsible to create or delete a Kubernetes (K8S) cluster on
Openstack. The K8S cluster is created using `kubeadm`.

## Go Application

The Go application is the container orchestrator that is responsible for translating commands
into actions: create, delete, help.

The Go application reads the Ephemeral cluster configuration file (e.g., openstack-config.yaml) and
converts the attributes into environment variables. These environment variables are used by the
shell scripts to create or delete the K8S cluster.

To build this Go application, execute the following commands:

```bash
go install .
go build -o capo-ephemeral
```

## Shell Scripts

The shell scripts make use of openstack cli commands to create and delete K8S cluster.
The other alternative that was considered was to use magnum container orchestration APIs.
In order to keep things generic, openstack cli command was chosen to create and delete the K8S
cluster.

### Create K8S Cluster script

The **create-k8s-cluster.sh** script creates a K8S cluster using the information provided in
the Ephemeral cluster configuration file. It passes `user-data.sh` script in the
`openstack server create` command to execute series of steps to initiate creation of the K8S
cluster at boot time. Once the cluster is created, its **kubeconfig** file is copied to the
container's volume mount, "sharing" it with the host.

### Delete K8S Cluster script

The **delete-k8s-cluster.sh** script deletes the underlying VM and the K8S cluster using the
information provided in the Ephemeral cluster configuration file.

## Dockerfile

The **Dockerfile** is used to build the Openstack Bootstrap container image.
Execute the following command to build the Bootstrap container image:

```bash
make docker
```

## Pre-requisite

- [Devstack](https://docs.openstack.org/devstack/latest/guides/devstack-with-lbaas-v2.html)
is installed.
- The most recent version of the *64-bit amd64-arch QCOW2* image for *Ubuntu 18.04* is used for
creating the ephemeral cluster.
 The image is available
 [here](https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img) for
 download and should be available in the devstack environment.

- `~/.airship/` directory on host machine contains `clouds.yaml` and `openstack-config.yaml` files.
- airship configuration file is updated with `ephemeral` cluster configuration information.

## Appendix

### Required Configuration

#### Ephemeral Cluster Configuration

```bash
$ cat openstack-config.yaml
apiVersion: v1
kind: OpenstackCloudConfig
metadata:
    name: capi-openstack
credentials:
    credential: clouds.yaml
    cloudName: devstack
spec:
    cluster:
        machineSize: ds4G
        kubeconfig: capo.kubeconfig
        securityGroup: bootstrap-sec-grp
```

#### Airship Configuration

```bash
$ cat ~/.airship/config
apiVersion: airshipit.org/v1alpha1
bootstrapInfo:
  ephemeral:
    container:
      image: quay.io/airshipit/capo-bootstrap:latest
      name: capo-bootstrap
      volume: /home/stack/.airship:/kube
    ephemeralCluster:
      config: openstack-config.yaml
```
