#!/usr/bin/env bash

arcion_jdbc_jars() {
if [ -z "$ARCION_HOME" ]; then ARCION_HOME="/arcion"; fi

if [ ! -d "$ARCION_HOME/lib" ]; then echo "Error: $ARCION_HOME/lib is not a directory" >&2 ; return 1; fi

if [ "${SRCDB_GRP}" = "oracle" ]; then
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
    $(ls /arcion/lib/snowflake-jdbc*jar) \
    $(ls /arcion/lib/GoogleBigQueryJDBC42*jar)  \
    /arcion/lib/db2jcc-db2jcc4*jar \
    | paste -sd:)
fi
}
