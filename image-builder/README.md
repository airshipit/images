# Overview

Image Builder is a utility used to produce two types of artifacts needed for an
airshipctl deployment: an iso (for the ephemeral node), and qcow2’s (used by
metal3io to deploy all other nodes). This is accomplished through several stages
as follows:

1. Build docker image containing the base operating system and basic configuration management
1. Run configuration management again with customized user-supplied inputs in container runtime
    - A more accessible layer for user customization that doesn't require rebuilding the container
    - Users may make their own decisions as to whether making a customized docker image build is worthwhile
1. Container runtime produces a final image artifact (ISO or QCOW2)

# Airship Image Variations

The ISO is built using the network information defined by the ephemeral node in the supplied airship manifests. Therefore, each airship deployment should have its own ISO created.

The QCOW2’s have such networking information driven by cloud-init during metal3io deployment, and therefore is not contained in the image itself. These QCOWs would therefore not necessarily be generated for each unique airship deployment, but rather for each for unique host profile.

Note that we will refer to the QCOW2s as the “base OS” or “target OS”, rather than “baremetal OS”, since the same process can be used to build QCOW2s for baremetal and for a virtualized environment.

# Building the image-builder container locally

If you do not wish to use the image-builder container published on quay.io, you may build your own locally as follows:

```
sudo apt -y install sudo git make
git clone https://review.opendev.org/airship/images
cd images/image-builder
sudo make DOCKER_REGISTRY=mylocalreg build
```

By default, both the ISO and QCOW share the same base container image. Therefore in most cases it should be sufficient to generate a single container that's reused for all image types and further differentiated in the container runtime phase described in the next section.

# Executing the image-builder container

The following makefile target may be used to execute the image-builder container in order to produce an ISO or QCOW2 output.

```
sudo apt -y install sudo git make
git clone https://review.opendev.org/airship/images
cd images/image-builder
sudo make IMAGE_TYPE=qcow cut_image
```

In the above example, set ``IMAGE_TYPE`` to ``iso`` or ``qcow`` as appropriate. This will be passed into the container to instruct it which type of image to build. Also include ``DOCKER_REGISTRY`` override if you wish to use a local docker image as described in the previous section.

This makefile target uses config files provided in the `images/image-builder/config` directory. **Modify these files as needed in order to customize your iso and qcow generation.** This provides a good place for adding and testing customizations to build parameters, without needing to modify the ansible playbooks themselves.

# Building behind a proxy

Example building docker container locally, plus ISO and qcow behind a proxy:

```
sudo apt -y install sudo git make
git clone https://review.opendev.org/airship/images
cd images/image-builder
# Create container
sudo make DOCKER_REGISTRY=mylocalreg PROXY=http://proxy.example.com:8080 build
# Create ephemeral ISO
sudo make DOCKER_REGISTRY=mylocalreg PROXY=http://proxy.example.com:8080 IMAGE_TYPE=iso cut_image
# Create qcow
sudo make DOCKER_REGISTRY=mylocalreg PROXY=http://proxy.example.com:8080 IMAGE_TYPE=qcow cut_image
```

# Useful testing flags

The `SKIP_MULTI_ROLE` build flag is useful if you would like to test local updates to the `osconfig` playbook, or updates to custom configs for this playbook. This saves time since you do not need to rebuild the target filesystem. For example:

```
sudo make SKIP_MULTI_ROLE=true build
```

Similiarly, osconfig and livecdcontent roles can be skipped using `SKIP_OSCONFIG_ROLE` and `SKIP_LIVECDCONTENT_ROLE` respectively. `SKIP_LIVECDCONTENT_ROLE` may be useful in combination with `SKIP_MULTI_ROLE` if you want to test out playbook changes to `osconfig` (however, it won't show up in the final bootable ISO image unless you don't skip `SKIP_LIVECDCONTENT_ROLE`).

# Division of Configuration Management responsibilities

Configuration management of the base OS is divided into several realms, each with their own focus:

1. Image-builder configuration data, i.e. data baked into the QCOW2 base image. The following should be used to drive this phase:
    1. The storage and compute elements of NCv1 host and hardware profiles (kernel boot params, cpu pinning, hugepage settings, disk partitioning, etc), and
    1. the NCv1 divingbell apparmor, security limits, file/dir permissions, sysctl, and
    1. custom-built kernel modules (e.g. dkms based installations, i40e driver, etc)
    1. Necessary components for the node’s bootstrap to k8s cluster, e.g. k8s, CNI, containerd, etc
    1. any other operating system setting which would require a reboot or cannot otherwise be accomodated in #2 below

1. cloud-init driven configuration for site-specific data. Examples include:
    1. Hostnames, domain names, FQDNs, IP addresses, etc
    1. Network configuration data (bonding, MTU settings, VLANs, DNS, NTP, ethtool settings, etc)
    1. Certificates, SSH keys, user accounts and/or passwords, etc.

1. HCA (host-config agent) for limited day-2 base-OS management
    1. Cron jobs, such as the Roomba cleanup script used in NCv1, or SACT/gstools scripts
    1. Possible overlapping of configuration-management items with #1 - #2, but for zero-disruption day-2 management (kept to a minimum to reduce design & testing complexity, only essential things to minimize overhead.)
    1. Eventually HCA may be phased out if #1 and #2 become streamlined enough and impact minimized to the degree that SLAs can be met, and use of HCA may be reduced or eliminated over time.

# Supported OSes

- Ubuntu 20.04 LTS

# FAQ

Q: Why is the build target slow?
A: There is a `mksquashfs` command which runs as part of the build target, and performs slowly if your build environment lacks certain CPU flags which accelerate compression. Use "host-passthrough" or equivalent in your build environment to pass through these CPU flags. In libvirt domain XML, you would change your `cpu` mode element as follows: `<cpu mode='host-passthrough' check='none'/>`
