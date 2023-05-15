#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# wait for dst db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS dst

# lower case it as Oracle will have it as upper case
sid_db=${DSTDB_SID:-${DSTDB_DB}}
db_schema=${DSTDB_DB:-${DSTDB_SCHEMA}}
db_schema_lower=${db_schema,,}

# setup database permissions
if [ -z "${EXISTING_DBS[${db_schema_lower}]}" ]; then
  echo "dst db ${DSTDB_ROOT}: ${DSTDB_DB} setup"

  for f in $( find ${CFG_DIR} -maxdepth 1 -name dst.init.root*sql ); do
    cat ${f} | jdbc_root_cli_dst  
  done
else
  echo "dst db ${DSTDB_DB} already setup. skipping db setup"
fi

# run if table needs to be created
if [ "${db_schema_lower}" = "${DSTDB_ARC_USER}" ]; then
  echo "dst db ${DSTDB_ARC_USER}: ${db_schema_lower} setup"

  for f in $( find ${CFG_DIR} -maxdepth 1 -name dst.init.user*sql ); do
    cat ${f} | jdbc_cli_dst
  done

else
  echo "dst db ${DSTDB_ARC_USER} ${db_schema_lower} skipping user setup"
fi



