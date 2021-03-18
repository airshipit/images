#!/bin/bash

# Defaults
ISO_NAME_DEFAULT='ephemeral.iso'

_validate_param(){
  PARAM_VAL="$1"
  PARAM_NAME="$2"
  # Validate that a paramter is defined (default) or that
  # it is defined and represents the path of a file or
  # directory that is found on the filesystem (VAL_TYPE=file)
  VAL_TYPE="$3"
  NO_NULL_EXIT="$4"
  echo "${PARAM_VAL:?}"
  # yq will return the 'null' string if a key is either undefined or defined with no value
  if [[ "${PARAM_VAL}" =~ null$ ]]
  then
    echo "variable ${PARAM_NAME} is not present in user-supplied config."
    if [[ "${NO_NULL_EXIT}" == 'no_null_exit' ]]; then
      echo "Using defaults"
    else
      exit 1
    fi
  else
    if [[ ${VAL_TYPE} == 'file' ]]; then
      if [[ ! -e "${PARAM_VAL}" ]]
      then
        echo "${PARAM_VAL} not exist"
        exit 1
      fi
    fi
  fi
}

# Capture stdin
stdin=$(cat)

yaml_dir=/tmp
echo "$stdin" > ${yaml_dir}/builder_config

OSCONFIG_FILE=osconfig
USER_DATA_FILE=user_data
NET_CONFIG_FILE=network_config
QCOW_CONFIG_FILE=qcow

file_list="${OSCONFIG_FILE}
${USER_DATA_FILE}
${NET_CONFIG_FILE}
${QCOW_CONFIG_FILE}"

IFS=$'\n'
for f in $file_list; do
  found_file=no
  for l in $stdin; do
    if [ "${l:0:1}" != " " ]; then
      found_file=no
    fi
    if [ "$found_file" = "yes" ]; then
      echo "$l" | sed 's/^    //g' >> ${yaml_dir}/${f}
    fi
    if [ "$l" = "${f}:" ]; then
      found_file=yes
    fi
  done
done
unset IFS

# Turn on -x after stdin is finished
set -x

# Output images to the first root-level mounted volume
for f in $(ls / | grep -v 'proc\|sys\|dev'); do mountpoint /$f >& /dev/null && VOLUME=/$f; done
if [ -z "$VOLUME" ]; then
  echo "Error: Could not find a root-level volume mount to output images. Exiting."
  exit 1
fi

# Read IMAGE_TYPE from the builder config yaml if not supplied as an env var
if [[ -z "${IMAGE_TYPE}" ]]; then
  # Make iso builds the default for backwards compatibility
  echo "NOTE: No IMAGE_TYPE specified. Assuming 'iso'."
  IMAGE_TYPE='iso'
fi

OUTPUT_FILE_NAME="$(yq r ${yaml_dir}/builder_config outputFileName)"

_make_metadata(){
  IMG_NAME="$1"
  # Write and print md5sum
  md5sum=$(md5sum "${VOLUME}/${IMG_NAME}" | awk '{print $1}')
  echo "md5sum:"
  echo "$md5sum" | tee "${VOLUME}/${IMG_NAME}.md5sum"
}

_process_input_data_set_vars_osconfig(){
  OSCONFIG_FILE="${yaml_dir}/${OSCONFIG_FILE}"
  # Optional user-supplied playbook vars
  if [[ -f "${OSCONFIG_FILE}" ]]; then
    echo "" >> /opt/assets/playbooks/roles/osconfig/vars/main.yaml
    cat "${OSCONFIG_FILE}" >> /opt/assets/playbooks/roles/osconfig/vars/main.yaml
  fi
}

_process_input_data_set_vars_iso(){
  # Required user provided input
  USER_DATA_FILE="${yaml_dir}/${USER_DATA_FILE}"
  if [ ! -e $USER_DATA_FILE ]; then
    echo "No user_data file supplied! Exiting."
    exit 1
  fi

  # Required user provided input
  NET_CONFIG_FILE="${yaml_dir}/${NET_CONFIG_FILE}"
  if [ ! -e $USER_DATA_FILE ]; then
    echo "No net_config file supplied! Exiting."
    exit 1
  fi
  # cloud-init expects net confing specifically in json format
  NET_CONFIG_JSON_FILE=/tmp/network_data.json
  yq r -j "${NET_CONFIG_FILE}" > "${NET_CONFIG_JSON_FILE}"

  # Optional user provided input
  if [[ ${OUTPUT_FILE_NAME} != null ]]; then
    IMG_NAME="${OUTPUT_FILE_NAME}"
  else
    IMG_NAME="${ISO_NAME_DEFAULT}"
  fi
  cat << EOF > /opt/assets/playbooks/roles/iso/vars/main.yaml
meta_data_file: ${BASEDIR}/meta_data.json
user_data_file: ${USER_DATA_FILE}
network_data_file: ${NET_CONFIG_JSON_FILE}
EOF
}

_process_input_data_set_vars_qcow(){
  IMG_NAME=null
  QCOW_CONFIG_FILE="${yaml_dir}/${QCOW_CONFIG_FILE}"
  # Optional user-supplied playbook vars
  if [[ -f "${QCOW_CONFIG_FILE}" ]]; then
    cp "${QCOW_CONFIG_FILE}" /opt/assets/playbooks/roles/qcow/vars/main.yaml
  fi

  # Retrieve from playbook defaults if not provided in user input
  if [[ "${IMG_NAME}" == 'null' ]]; then
    IMG_NAME="$(yq r /opt/assets/playbooks/roles/qcow/defaults/main.yaml img_name)"
  fi

  # User-supplied image output name in builder-config takes precedence
  if [[ ${OUTPUT_FILE_NAME} != null ]]; then
    IMG_NAME="${OUTPUT_FILE_NAME}"
  else
    _validate_param "${IMG_NAME}" img_name
  fi
}

