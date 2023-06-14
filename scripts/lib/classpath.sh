#!/usr/bin/env bash

arcion_jdbc_jars() {
local LOC="${1:-src}" # SRC|DST
local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )

if [ -z "$ARCION_HOME" ]; then ARCION_HOME="/arcion"; fi

if [ ! -d "$ARCION_HOME/lib" ]; then echo "Error: $ARCION_HOME/lib is not a directory" >&2 ; return 1; fi

if [ "${db_grp}" = "oracle" ]; then
  echo $(ls ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd:)
else
  echo $(ls \
    ${ARCION_HOME}/lib/maria*jar \
    ${ARCION_HOME}/lib/post*jar \
    ${ARCION_HOME}/lib/mongodb*jar \
    ${ARCION_HOME}/lib/mssql*jar \
    ${ARCION_HOME}/lib/db2*jar \
    ${ARCION_HOME}/lib/jconn4*jar \
    ${ARCION_HOME}/lib/jdbc-*jar \
    ${ARCION_HOME}/lib/bson-*jar \
    $(find ${ARCION_HOME} -name "snowflake-jdbc*jar") \
    $(find ${ARCION_HOME} -name "GoogleBigQueryJDBC42*jar")  \
    ${ARCION_HOME}/db2jcc-db2jcc4*jar \
    | paste -sd:)
fi
}
