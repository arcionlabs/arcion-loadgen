#!/usr/bin/env bash

prep_arcion_lic() {

if [ -f "$ARCION_HOME/replicant.lic" ]; then
  echo "$ARCION_HOME/replicant.lic not found." >&2
  exit 1
elif [ -f "$SCRIPTS_DIR/utils/arcion/general.yaml" ]; then
  echo "checking $SCRIPTS_DIR/utils/arcion/general.yaml"
  license_path=$( cat $SCRIPTS_DIR/utils/arcion/general.yaml | \
    yq -r '."license-path"')
  echo "license_path=${license_path}"
  if [ -n "${license_path}" ] && [ -f "${license_path}" ]; then 
    echo "license ${license_path} exists"
  else
    echo "Error: license ${license_path} does not exists"
    exit 1
  fi
else
  echo "Error: $ARCION_HOME/replicant.lic nor $SCRIPTS_DIR/utils/arcion/general.yaml exists"
fi

}