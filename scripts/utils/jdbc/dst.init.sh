#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh
. $SCRIPTS_DIR/lib/jdbc_cli.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# lower case it as Oracle will have it as upper case
sid_db=${DSTDB_SID:-${DSTDB_DB}}
db_schema=${DSTDB_DB:-${DSTDB_SCHEMA}}
db_schema_lower=${db_schema,,}

# wait for dst db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS dst

rc=$?
if (( ${rc} != 0 )); then 
  echo "dst.init.sh: timeout from ping_db."
  exit $rc
fi

echo "Existing Database Table count looking for ${db_schema_lower}"
declare -p EXISTING_DBS

# delete target if exists
#if [ "${gui_run}" != "1" ] && [ -z "$workload_preserve_dst" ] && [ -n "${EXISTING_DBS[${db_schema_lower}]}" ]; then
#  echo "dropping destination database ${DSTDB_DB}"
#  echo "drop database ${DSTDB_DB};" | jdbc_root_cli_dst
#  unset EXISTING_DBS[${db_schema_lower}]
#else
#  echo "NOT dropping destination database ${DSTDB_DB}. gui_run='${gui_run}' workload_preserve_dst='${workload_preserve_dst}' existing_db='${EXISTING_DBS[${db_schema_lower}]}'"
#fi

# setup database permissions
if [ -z "${EXISTING_DBS[${db_schema_lower}]}" ]; then
  echo "dst db ${DSTDB_ROOT}: ${DSTDB_DB} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name dst.init.root*sql ); do
    echo ${f}
    cat ${f} | jdbc_root_cli_dst   
  done
else
  echo "dst db ${DSTDB_DB} already setup. skipping db setup"
  # drop tables from dst
  drop_all_tables dst
fi

# run if table needs to be created
if [ "${db_schema_lower}" = "${DSTDB_ARC_USER}" ]; then
  echo "dst db ${DSTDB_ARC_USER}: ${db_schema_lower} setup"

  for f in  $( find ${CFG_DIR} -maxdepth 1 -name dst.init.user*sql ); do
    echo ${f}
    cat ${f} | jdbc_cli_dst
  done

else
  echo "dst db ${DSTDB_ARC_USER} ${db_schema_lower} skipping user setup"
fi



