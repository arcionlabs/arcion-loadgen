#!/usr/bin/env bash 

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi
CLASSPATH=$(ls ${ARCION_HOME}/lib/maria* ${ARCION_HOME}/lib/post* ${ARCION_HOME}/lib/mongodb* ${ARCION_HOME}/lib/ora* ${ARCION_HOME}/lib/mssql* ${ARCION_HOME}/lib/db2*| paste -sd:)
