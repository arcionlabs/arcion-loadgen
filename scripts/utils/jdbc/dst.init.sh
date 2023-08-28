#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh
. $SCRIPTS_DIR/lib/jdbc_cli.sh
. $SCRIPTS_DIR/lib/yaml_key_val.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# lower case it as Oracle will have it as upper case
sid_db=${DSTDB_SID:-${DSTDB_DB}}
db_schema=${DSTDB_DB:-${DSTDB_SCHEMA}}
db_schema_lower=${db_schema,,}

# get the host and port from YAML
DB_HOST=$( get_host_from_yaml ${CFG_DIR}/dst.yaml host )
DB_PORT=$( yaml_key_val ${CFG_DIR}/dst.yaml port )

ping_host_port "$DB_HOST" "$DB_PORT"

rc=$?
if (( ${rc} != 0 )); then 
  echo "dst.init.sh: timeout from ping_db."
  exit $rc
fi

# wait for dst db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS dst

echo "Existing Database Table count looking for ${db_schema_lower}"
declare -p EXISTING_DBS

# setup database permissions
if [ -z "${EXISTING_DBS[${db_schema_lower}]}" ]; then
  echo "dst db ${DSTDB_ROOT}: ${sid_db} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name dst.init.root*sql ); do
    echo ${f}
    cat ${f} | jdbc_root_cli_dst   
  done
else
  echo "dst db ${db_schema_lower} already setup. skipping db setup"
  # drop tables from dst
  case ${REPL_TYPE,,} in
    snapshot|full|delta-snapshot)
      echo "dst db ${db_schema_lower} dropping tables"
      drop_all_tables dst
      ;;
    *)
      echo "dst db ${db_schema_lower} leaving tables as is"
      ;;
  esac
fi

# run if table needs to be created
if [ "${db_schema_lower}" = "${DSTDB_USER_PREFIX}arcdst" ]; then
  echo "dst db ${sid_db}: ${db_schema_lower} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name dst.init.user*sql ); do
    echo ${f}
    cat ${f} | jdbc_cli_dst
  done

else
  echo "dst db ${DSTDB_USER_PREFIX}arcdst != ${db_schema_lower} skipping user setup"
fi