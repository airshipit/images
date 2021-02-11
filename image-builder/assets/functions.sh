#!/bin/bash
# NOTE: These functions are deprecated. It is only left here
# for backwards compatibility until airshipctl is migrated
# away from using it.
set -x

# Defaults
OUTPUT_METADATA_FILE_NAME_DEFAULT='output-metadata.yaml'
ISO_NAME_DEFAULT='ephemeral.iso'

# Common
echo "${BUILDER_CONFIG:?}"
if [ ! -f "${BUILDER_CONFIG}" ]
then
  echo "file ${BUILDER_CONFIG} not found"
  exit 1
fi

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
    echo "variable ${PARAM_NAME} is not present in ${BUILDER_CONFIG}"
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

IFS=':' read -ra ADDR <<<"$(yq r "${BUILDER_CONFIG}" container.volume)"
HOST_PATH="${ADDR[0]}"
VOLUME="${ADDR[1]}"
_validate_param "${VOLUME}" "container.volume" file

# Read IMAGE_TYPE from the builder config yaml if not supplied as an env var
if [[ -z "${IMAGE_TYPE}" ]]; then
  IMAGE_TYPE="$(yq r "${BUILDER_CONFIG}" "builder.imageType")"
  # Make iso builds the default for backwards compatibility
  if [[ "${IMAGE_TYPE}" == 'null' ]]; then
    echo "NOTE: No builder.imageType specified. Assuming 'iso'."
    IMAGE_TYPE='iso'
  fi
fi

if [[ -z "${OUTPUT_METADATA_FILE_NAME}" ]]; then
  OUTPUT_METADATA_FILE_NAME="$(yq r "${BUILDER_CONFIG}" builder.outputMetadataFileName)"
  if [[ "${OUTPUT_METADATA_FILE_NAME}" == 'null' ]]; then
    echo "NOTE: No builder.outputMetadataFileName specified. Assuming '${OUTPUT_METADATA_FILE_NAME_DEFAULT}'."
    OUTPUT_METADATA_FILE_NAME="${OUTPUT_METADATA_FILE_NAME_DEFAULT}"
  fi
fi

OUTPUT_FILE_NAME="$(yq r "${BUILDER_CONFIG}" builder.outputFileName)"

_make_metadata(){
  IMG_NAME="$1"
  OUTPUT_METADATA_FILE_PATH="${VOLUME}/${OUTPUT_METADATA_FILE_NAME}"
  # Instruct airshipctl where to locate the output image artifact
  echo "bootImagePath: ${HOST_PATH}/${IMG_NAME}" > "${OUTPUT_METADATA_FILE_PATH}"
  # Also include the image md5sum
  md5sum=$(md5sum "${VOLUME}/${IMG_NAME}" | awk '{print $1}')
  echo "md5sum: $md5sum" | tee -a "${OUTPUT_METADATA_FILE_PATH}"
}

_process_input_data_set_vars_osconfig(){
  if [[ -z "${OSCONFIG_FILE}" ]]; then
    OSCONFIG_FILE="$(yq r "${BUILDER_CONFIG}" builder.osconfigVarsFileName)"
  fi
  OSCONFIG_FILE="${VOLUME}/${OSCONFIG_FILE}"
  _validate_param "${OSCONFIG_FILE}" builder.osconfigVarsFileName file no_null_exit
  # Optional user-supplied playbook vars
  if [[ -f "${OSCONFIG_FILE}" ]]; then
    cp "${OSCONFIG_FILE}" /opt/assets/playbooks/roles/osconfig/vars/main.yaml
  fi
}

_process_input_data_set_vars_iso(){
  # Required user provided input
  if [[ -z "${USER_DATA_FILE}" ]]; then
    USER_DATA_FILE="$(yq r "${BUILDER_CONFIG}" builder.userDataFileName)"
  fi
  USER_DATA_FILE="${VOLUME}/${USER_DATA_FILE}"
  _validate_param "${USER_DATA_FILE}" builder.userDataFileName file

  # Required user provided input
  if [[ -z "${NET_CONFIG_FILE}" ]]; then
    NET_CONFIG_FILE="$(yq r "${BUILDER_CONFIG}" builder.networkConfigFileName)"
  fi
  NET_CONFIG_FILE="${VOLUME}/${NET_CONFIG_FILE}"
  _validate_param "${NET_CONFIG_FILE}" builder.networkConfigFileName file
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
  if [[ -z "${QCOW_CONFIG_FILE}" ]]; then
    QCOW_CONFIG_FILE="$(yq r "${BUILDER_CONFIG}" builder.qcowVarsFileName)"
  fi
  QCOW_CONFIG_FILE="${VOLUME}/${QCOW_CONFIG_FILE}"
  _validate_param "${QCOW_CONFIG_FILE}" builder.qcowVarsFileName file no_null_exit
  # Optional user-supplied playbook vars
  if [[ -f "${QCOW_CONFIG_FILE}" ]]; then
    cp "${QCOW_CONFIG_FILE}" /opt/assets/playbooks/roles/qcow/vars/main.yaml

    # Extract the image output name in the ansible vars file provided
    IMG_NAME="$(yq r "${QCOW_CONFIG_FILE}" img_name)"
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

