#!/usr/bin/env bash

[ -z "${YCSB_JDBC}" ] && export YCSB_JDBC=/opt/ycsb/ycsb-jdbc-binding-0.18.0-SNAPSHOT

# source in libs
. $(dirname "${BASH_SOURCE[0]}")/lib/ycsb_jdbc.sh

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

sid_db=${SRCDB_SID:-${SRCDB_DB}}
db_schema=${SRCDB_DB:-${SRCDB_SCHEMA}}
db_schema_lower=${db_schema,,}

if [ "${SRCDB_ARC_USER}" != "${db_schema_lower}" ]; then
  echo "ycsb run $LOC: "${SRCDB_ARC_USER}" != "${db_schema_lower} skipping
  exit
fi

# start the YCSB
case "${SRCDB_GRP,,}" in
  mysql|postgresql|sqlserver|informix|oracle)
    ycsb_run_src
;;
  mongodb)
    pushd ${YCSB_MONGODB}  
    bin/ycsb.sh load mongodb -s -threads ${args_ycsb_threads} -target ${args_ycsb_rate} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((1000000*$args_ycsb_threads)) \
    -p mongodb.url="${SRCDB_JDBC_URL}"
    popd  
    ;; 
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support"
    ;;
esac 
