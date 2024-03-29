#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh
. $SCRIPTS_DIR/lib/jdbc_cli.sh
. $SCRIPTS_DIR/lib/yaml_key_val.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# lower case it as Oracle will have it as upper case
sid_db=${SRCDB_SID:-${SRCDB_DB}}
db_schema=${SRCDB_DB:-${SRCDB_SCHEMA}}
db_schema_lower=${db_schema,,}

# get the host and port from YAML
DB_HOST=$( get_host_from_yaml ${CFG_DIR}/src.yaml host )
DB_PORT=$( yaml_key_val ${CFG_DIR}/src.yaml port )

ping_host_port "$DB_HOST" "$DB_PORT"

rc=$?
if (( ${rc} != 0 )); then 
  echo "src.init.sh: timeout from ping_db."
  exit $rc
fi

# wait for src db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS src

echo "Existing Database Table count looking for ${db_schema_lower}"
declare -p EXISTING_DBS

# setup database permissions
if [ -z "${EXISTING_DBS[${db_schema_lower}]}" ]; then
  echo "src db root ${SRCDB_ROOT} database ${sid_db}:${db_schema_lower} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name src.init.root*sql ); do
    cat ${f} | jdbc_root_cli_src "${JSQSH_CSV}"
  done
else
  echo "src db root ${SRCDB_ROOT} database ${sid_db}:${db_schema_lower} already setup. skipping db setup"
fi

# run if table needs to be created
if [ "${db_schema_lower}" = "${SRCDB_USER_PREFIX}arcsrc" ]; then
  echo "src db user ${SRCDB_ARC_USER} database ${sid_db}:${db_schema_lower} setup"

  for f in $( find ${CFG_DIR} -maxdepth 1 -name src.init.user*sql ); do
    cat ${f} | jdbc_cli_src "${JSQSH_CSV}"
  done

else
  echo "src db user ${SRCDB_USER_PREFIX}arcsrc != ${db_schema_lower} skipping workload setup"
fi

# setup workloads
if [ "${db_schema_lower}" = "${SRCDB_USER_PREFIX}arcsrc" ]; then
  echo "src db ${SRCDB_DB}: benchbase setup"
  # benchbase data population
  ${SCRIPTS_DIR}/bin/benchbase-load.sh

  # ycsb data population 
  echo "src db ${SRCDB_DB}: ycsb setup"
  ${SCRIPTS_DIR}/bin/ycsb-load.sh

else
  echo "src db ${SRCDB_USER_PREFIX}arcsrc != ${db_schema_lower} skipping workload setup"
fi
