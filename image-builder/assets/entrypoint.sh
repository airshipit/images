#!/bin/bash
set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
BASEDIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
cd "$BASEDIR"

BASEDIR="$(dirname "$(realpath "$0")")"
if [ "${VERSION}" = "v2" ]; then
  source "${BASEDIR}/functions_v2.sh"
else
  source "${BASEDIR}/functions.sh"
fi

export http_proxy
export https_proxy
export HTTP_PROXY
export HTTPS_PROXY
export no_proxy
export NO_PROXY

if [ ! -e build ]; then
  ln -s /chroot build
fi

# Instruct ansible to output the image artifact to the container's host mount
extra_vars="$extra_vars img_output_dir=${VOLUME}"

echo "Begin Ansible plays"
if [[ "${IMAGE_TYPE}" == "iso" ]]; then
  _process_input_data_set_vars_iso

  # Instruct ansible how to name image output artifact
  extra_vars="$extra_vars img_name=${IMG_NAME}"

  echo "Executing Step 1"
  ansible-playbook -i /opt/assets/playbooks/inventory.yaml /opt/assets/playbooks/iso.yaml --extra-vars "$extra_vars" -vv
elif [[ "${IMAGE_TYPE}" == "qcow" ]]; then
  _process_input_data_set_vars_qcow
  _process_input_data_set_vars_osconfig

  # Instruct ansible how to name image output artifact
  extra_vars="$extra_vars img_name=${IMG_NAME} run_context=qcow"

  echo "Executing Step 1: Create qcow2 partitions and filesystems"
  ansible-playbook -i /opt/assets/playbooks/inventory.yaml /opt/assets/playbooks/qcow.yaml --extra-vars "$extra_vars" --tags "prep_img" -vv

  echo "Executing Step 2: Applying changes from base-osconfig playbook"
  ansible-playbook -i /opt/assets/playbooks/inventory.yaml /opt/assets/playbooks/base-osconfig.yaml --extra-vars "$extra_vars" -vv

  echo "Executing Step 3: Close image and write qcow2"
  ansible-playbook -i /opt/assets/playbooks/inventory.yaml /opt/assets/playbooks/qcow.yaml --extra-vars "$extra_vars" --tags "close_img" -vv
else
  echo "\${IMAGE_TYPE} value '${IMAGE_TYPE}' does not match an expected value: [ 'iso', 'qcow' ]"
  exit 1
fi

# Write md5sum
_make_metadata "${IMG_NAME}"

echo "All Ansible plays completed successfully"

