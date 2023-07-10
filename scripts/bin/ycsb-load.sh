#!/usr/bin/env bash



# get the setting from the menu
if [ ! -z "${CFG_DIR}" ] && [ -f "${CFG_DIR}/ini_menu.sh" ]; then
    echo "sourcing . ${CFG_DIR}/ini_menu.sh"
    . ${CFG_DIR}/ini_menu.sh
elif [ -f /tmp/ini_menu.sh ]; then
    echo "sourcing . /tmp/ini_menu.sh"
    . /tmp/ini_menu.sh
else
    echo "CFG_DIR=${CFG_DIR} or /tmp/ini_menu.sh did not have ini_menu.sh" >&2
    exit 1
fi 

# process command line args that may override ini_menu.sh

# set the version of YCBS to use
[ -z "${YCSB_JDBC}" ] && export YCSB_JDBC=/opt/ycsb/ycsb-jdbc-binding-0.18.0-SNAPSHOT

sid_db=${SRCDB_SID:-${SRCDB_DB}}
db_schema=${SRCDB_DB:-${SRCDB_SCHEMA}}
db_schema_lower=${db_schema,,}

#if [ "${SRCDB_ARC_USER}" != "${db_schema_lower}" ]; then
#  echo "ycsb run $LOC: "${SRCDB_ARC_USER}" != "${db_schema_lower} skipping
#  exit
#fi

# start the YCSB
case "${SRCDB_GRP,,}" in
  db2|informix|mysql|oracle|postgresql|snowflake|sqlserver)
  # source in libs
    . ${SCRIPTS_DIR}/lib/ycsb_jdbc.sh
    ycsb_load_src "$@"
    ;;
  mongodb)
    pushd ${YCSB_MONGODB} >/dev/null 
    bin/ycsb.sh load mongodb -s -threads ${args_ycsb_threads} -target ${args_ycsb_rate} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((1000000*$args_ycsb_threads)) \
    -p mongodb.url="${SRCDB_JDBC_URL}"
    popd >/dev/null 
    ;; 
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to be supported"
    ;;
esac 
