Directory structure:

|-- config
  |-- iso
    +-- network_data.json
    +-- user_data
  |-- qcow-bundle
    |-- qcow-control-plane
      +-- img_name
      +-- osconfig-control-plane-vars.yaml
      +-- qcow-control-plane-vars.yaml
    |-- qcow-data-plane
      +-- img_name
      +-- osconfig-control-plane-vars.yaml
      +-- qcow-control-plane-vars.yaml

The `generate_iso` and `package_qcow` make target can be used to build ISO and
QCOW artifacts respectively, after the shared `image-builder` container is
built (built with the `build` target).

The ISO always builds out of the `config/iso` directory, because this is only
used for local testing. It is not an artifact that is promoted or published.

QCOWs are grouped into publishable "bundles", i.e. a container image where all
QCOWs needed for a given deployment are stored. A bundle will be built for each
`config/qcow-bundle*` directory. Each `config/qcow-bundle*` directory contains
one subdirectory per QCOW that is part of that bundle, where overrides for
those images can be placed.

The following items are expected in the `iso` directory:
- `user_data` - YAML file containing cloud-init user-data
- `network_data.json` - JSON file containing cloud-init network data

QCOWs expect the following files to be present in their directory:
- `img_name` - text file containing the desired name for the image
- `osconfig-*-vars.yaml` - YAML file containing `osconfig` playbook overrides
- `qcow-*-vars.yaml` - YAML file containing `qcow` playboook overrides
