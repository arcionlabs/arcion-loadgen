#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# wait for src db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS src

# lower case it as Oracle will have it as upper case
sid_db=${SRCDB_SID:-${SRCDB_DB}}
db_schema=${SRCDB_DB:-${SRCDB_SCHEMA}}
db_schema_lower=${db_schema,,}

# setup database permissions
if [ 1 ] || [ -z "${EXISTING_DBS[${db_schema_lower}]}" ]; then
  echo "src db ${SRCDB_ROOT}: ${SRCDB_DB} setup"

  for f in $( find ${CFG_DIR} -maxdepth 1 -name src.init.root*sql ) ; do
    cat ${f} | jdbc_root_cli_src
  done
else
  echo "src db ${SRCDB_DB} already setup. skipping db setup"
fi

# run if table needs to be created
if [ "${db_schema_lower}" = "${SRCDB_ARC_USER}" ]; then
  echo "src db ${SRCDB_ARC_USER}: ${db_schema_lower} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name src.init.user*sql ); do
    cat ${f} | jdbc_cli_src
  done

else
  echo "src db ${SRCDB_ARC_USER} ${db_schema_lower} skipping user setup"
fi

# setup workloads
if [ "${db_schema_lower}" = "${SRCDB_ARC_USER}" ]; then
  echo "src db ${SRCDB_ARC_USER}: benchbase setup"
  # benchbase data population
  ${SCRIPTS_DIR}/bin/benchbase-load.sh

  # ycsb data population 
  echo "src db ${SRCDB_ARC_USER}: ycsb setup"
  ycsb_load_src

else
  echo "src db ${SRCDB_ARC_USER} != ${db_schema_lower} skipping workload setup"
fi
