#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

if [ -f "${ARCION_HOME}/replicant.lic" -o -z "${ARCION_LICENSE}" ]; then 
    echo "${ARCION_HOME}/replicant.lic skipped"
else
    echo "${ARCION_HOME}/replicant.lic set"
    echo $ARCION_LICENSE | base64 -d > ${ARCION_HOME}/replicant.lic
fi