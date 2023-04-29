#!/usr/bin/env bash 

# this file should be in $YCSB/bin dir

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

# mariadb maria*
# postgres post*
# mongodb mongo *
# mssql mssql*
# db2 db2*
# sybase jconn4
# informix jdbc-*jar
# informix bson-*jar
# oracle ojdbc-*.jar
# oracle jar does does not play nice with mysql
if [ "${SRCDB_GRP}" = "oracle" ]; then
  CLASSPATH=$(ls /libs/ojdbc8*jar | paste -sd:)
else
  CLASSPATH=$(ls ${ARCION_HOME}/lib/maria* ${ARCION_HOME}/lib/post* ${ARCION_HOME}/lib/mongodb* ${ARCION_HOME}/lib/mssql* ${ARCION_HOME}/lib/db2* ${ARCION_HOME}/lib/jconn4*jar ${ARCION_HOME}/lib/jdbc-*jar ${ARCION_HOME}/lib/bson-*jar | paste -sd:)
fi