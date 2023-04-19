#!/usr/bin/env bash 

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

# informix jdbc-*jar
# informix bson-*jar
# oracle ojdbc-*.jar
CLASSPATH=$(ls ${ARCION_HOME}/lib/maria* ${ARCION_HOME}/lib/post* ${ARCION_HOME}/lib/mongodb* ${ARCION_HOME}/lib/ora* ${ARCION_HOME}/lib/mssql* ${ARCION_HOME}/lib/db2* ${ARCION_HOME}/lib/jconn4*jar ${ARCION_HOME}/lib/jdbc-*jar ${ARCION_HOME}/lib/bson-*jar ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd:)
