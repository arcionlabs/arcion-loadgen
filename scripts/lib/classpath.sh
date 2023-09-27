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
  echo $(find ${ARCION_HOME}/lib/ojdbc8*jar | paste -sd:)
else
  echo $(ls \
      ${ARCION_HOME}/lib/maria*jar \
      ${ARCION_HOME}/lib/post*jar \
      ${ARCION_HOME}/lib/vertica*jar \
      ${ARCION_HOME}/lib/mongodb*jar \
      ${ARCION_HOME}/lib/mssql*jar \
      ${ARCION_HOME}/lib/db2*jar \
      ${ARCION_HOME}/lib/jconn4*jar \
      ${ARCION_HOME}/lib/jdbc-*jar \
      ${ARCION_HOME}/lib/bson-*jar \
      ${ARCION_HOME}/lib/db2jcc-db2jcc4*jar \
    $(find ${ARCION_HOME}/lib/snowflake-jdbc*jar) \
    $(find ${ARCION_HOME}/lib/GoogleBigQueryJDBC42*jar) \
    | paste -sd:)
fi
}
