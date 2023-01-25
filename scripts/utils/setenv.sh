#!/usr/bin/env bash 

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi
CLASSPATH=$(ls ${ARCION_HOME}/lib/maria* ${ARCION_HOME}/lib/post* | paste -sd:)