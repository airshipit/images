The `generate_iso` and `package_qcow` make target can be used to build ISO and
QCOW artifacts respectively, after the shared `image-builder` container is
built (built with the `build` target).

By default, one image will be built for each subdirectory that matches the
corresponding `IMAGE_TYPE` for the build.

In other words, ISOs will be built using files from subdirs with names starting
with `iso*`, while QCOWs are built from subdirs with names starting with
`qcow*`. If you want to build QCOWs from an explicit list of dirs, you can
supply them using the `QCOW_CONF_DIRS` parameter to the makefile.

ISOs expect the following files to be present in their directory:
- `user_data` - YAML file containing cloud-init user-data
- `network_data.json` - JSON file containing cloud-init network data
- `img_name` - text file containing the desired name for the image

Note that ISO generation here is *only* for testing. It is not published or
promoted anywhere.

QCOWs expect the following files to be present in their directory:
- `osconfig-*-vars.yaml` - YAML file containing `osconfig` playbook overrides
- `qcow-*-vars.yaml` - YAML file containing `qcow` playboook overrides
- `img_name` - text file containing the desired name for the image
