#!/usr/bin/env bash

if [ -f "${ARCION_HOME}/replicant.lic" -o -z "${ARCION_LICENSE}" ]; then 
    echo "${ARCION_HOME}/replicant.lic skipped"
else
    echo "${ARCION_HOME}/replicant.lic set"
    echo $ARCION_LICENSE | base64 -d > ${ARCION_HOME}/replicant.lic
fi