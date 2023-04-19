#!/usr/bin/env bash

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

if [ -f "${ARCION_HOME}/replicant.lic" -o -z "${ARCION_LICENSE}" ]; then 
    echo "${ARCION_HOME}/replicant.lic skipped"
else
    echo "${ARCION_HOME}/replicant.lic set"
    # try if gzip
    echo "$ARCION_LICENSE" | base64 -d | gzip -d > ${ARCION_HOME}/replicant.lic
    # try non gzip
    if [ "$?" != 0 ]; then
        echo "$ARCION_LICENSE" | base64 -d > ${ARCION_HOME}/replicant.lic
    fi
fi
cat ${ARCION_HOME}/replicant.lic
