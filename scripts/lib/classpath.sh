#!/usr/bin/env bash

copy_jars_to_arcion_home() {
  # if arcion_home could changed, then the libs might not be there
  local DBJARS=( snowflake-jdbc*jar ojdbc8*jar GoogleBigQueryJDBC42*jar )
  for j in ${DBJARS[@]}; do
    if [[ -z $(find ${ARCION_HOME}/lib -name "${j}" ) ]]; then
      if [[ -n $(find /opt/stage/libs -name "${j}" ) ]]; then
        echo cp /opt/stage/libs/${j} ${ARCION_HOME}/lib/. >&2
        cp /opt/stage/libs/${j} ${ARCION_HOME}/lib/.
      fi
    fi
  done
}

arcion_jdbc_jars() {
local LOC="${1:-src}" # SRC|DST
local db_grp=$( x="${LOC^^}DB_GRP"; echo "${!x}" )

copy_jars_to_arcion_home

if [ -z "$ARCION_HOME" ]; then ARCION_HOME="/arcion"; fi

if [ ! -d "$ARCION_HOME/lib" ]; then echo "Error: $ARCION_HOME/lib is not a directory" >&2 ; return 1; fi

# figure out the classpath
if [ "${db_grp}" = "oracle" ]; then
  find ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd:
else
  find ${ARCION_HOME}/lib \
    -name maria*jar \
    -o -name post*jar \
    -o -name vertica*jar \
    -o -name mongodb*jar \
    -o -name mssql*jar \
    -o -name db2*jar \
    -o -name jconn4*jar \
    -o -name jdbc-*jar \
    -o -name bson-*jar \
    -o -name db2jcc-db2jcc4*jar \
    -o -name snowflake-jdbc*jar \
    -o -name GoogleBigQueryJDBC42*jar \
  | paste -sd:
fi
}
