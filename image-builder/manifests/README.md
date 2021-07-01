# Directory structure:

```
|-- manifests
  |-- iso
    +-- network_data.json
    +-- user_data
  |-- qcow-bundle-[bundle name]
    |-- control-plane
      +-- osconfig-vars.yaml
      +-- qcow-vars.yaml
    |-- data-plane
      +-- osconfig-vars.yaml
      +-- qcow-vars.yaml
  |-- rootfs
    |-- livecdcontent-vars.yaml
    |-- multistrap-vars.yaml
    |-- osconfig-vars.yaml
  |-- scripts
    |-- common
    |-- qcow
```

## iso

The image-builder `generate_iso` makefile target can be used to build the
ephemeral ISO using the test config data stored under the `manifests/iso`
directory.

This is *only* for testing. It is *not* an artifact promoted or published. The
final ISO is built by airshipctl, where the network\_data and user\_data are
sourced from airshipctl manifests.

The following items are expected in the `manifests/iso` directory when using
the `generate_iso` makefile target:
- `user_data` - YAML file containing cloud-init user-data
- `network_data.json` - JSON file containing cloud-init network data

## qcow-bundles

The image-builder `package_qcow` makefile target can be used to build the QCOW
artifacts sourced from the manifests/qcow-bundle-\* directories.

QCOWs are grouped into publishable "bundles", i.e. a container image where all
QCOWs needed for a given deployment are stored. A bundle will be built for each
`manifests/qcow-bundle*` directory. Each `manifests/qcow-bundle*` directory contains
one subdirectory per QCOW that is part of that bundle, where overrides for
those images can be placed.

QCOWs expect the following files to be present in their directory:
- `osconfig-vars.yaml` - YAML file containing `osconfig` playbook overrides
- `qcow-vars.yaml` - YAML file containing `qcow` playboook overrides

## rootfs

This directory contains a number of image-builder ansible playbook overrides
which are applied to base-image inherited by all ISO and QCOWs.

`livecdcontent-vars.yaml` contains overrides to the livecdcontent playbook.

`multistrap-vars.yaml` contains overrides to the `multistrap` playbook.

`osconfig-vars.yaml` contains overrides to the `osconfig` playbook.
NOTE: qcow-bundles contains another level of `osconfig-vars` overrides, which
are applied on top of these common overrides. This common `osconfig-vars`
overrides should be used for playbook overrides, except in cases where those
overrides are actually unique to a particular QCOW variation (e.g., hugepages,
cpu pinning, or other hardware-specific configs).

## scripts

This is a convenience directory for adding scripts that run when building images.
These scripts run in the chroot of the target image. For example, a script that
writes 'hello world' to `/hello-world.txt` will appear in the same path on the
target image.

Use the `manifests/scripts/qcow` directory for scripts that should only run
when building the QCOWs. Use the `manifests/scripts/common` directory for
scripts that are applied to the base container image, which is inherited both by
the QCOWs as well as by the ephemeral ISO.

No additional configuration is needed for these scripts to run. Just add your
script(s) to these directories as needed.

# Customizing images in your environment

Keep in mind that some tasks could also be accomplished by cloud-init or by
the hostconfig operator instead. Refer to the parent image-builder README to
understand the different use-cases for each and to determine the best option
for your use-case. These are lower-effort paths if they support your use-case.

If you determine that you do require image customizations, start with a manual
image build to reduce complexity:

1. Clone this repository in your environment.
1. Make any desired changes to the `manifests` directory to customize the
   image, as described in prior sections.
1. Perform a `docker login` to the docker registry you will publish image
   artifacts to. This should be a registry you have credentials for and that
   is accessible by the environment which you plan to consume these artifacts,
   (e.g., airshipctl).
1. Run the `make images` target to generate image artifacts. Ensure that the
   `PUSH_IMAGE` environment variable is set to `true`, and that the
   `DOCKER_REGISTRY` environment variable is set to the container image
   repository you performed the login for in the previous step.

Perform an end-to-end to deployment (e.g., with airshipctl) to verify your
customized image performs as you expect and works properly.

Now after getting this working, there are several options to proceed depending
on the nature of the changes:
1. Some set of changes to defaults could be proposed upstream (e.g., package
   install list). This may be appropriate for changes that are useful for
   everyone. In this case, you don't need a custom image because the changes
   will be reflected in the image produced upstream.
1. Some enhancements or additions to ansible playbooks to configure some other
   aspects of the image, which are useful for everyone and proposed upstream.
   In this case, you would be able to leverage ansible overrides to customize
   your image with ansible playbooks that are maintained/adopted upstream.
1. Some change to image configuration that is specific to your needs and not
   appropriate to be upstreamed.

In the case of #2 or #3 where you have some portion of image config changes that
are specific to your use-case (i.e. not part of the default upstream image),
and you want to perform regular rebuilds with the latest upstream image-builder
plus your customized changes on top, then you can setup a Zuul child-job that
interfaces with the image-builder parent-job to accomplish this.

By overriding the `image_config_dir` zuul variable in your child-job, the
image-builder Makefile will use use your customized manifests in place of the
`manifests` directory that is present in upstream image-builder.
