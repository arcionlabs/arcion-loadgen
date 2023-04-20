#!/usr/bin/env bash

# source in libs
. $(dirname "${BASH_SOURCE[0]}")/lib/ycsb_jdbc.sh

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

if [ "${SRCDB_ARC_USER,,}" != "${SRCDB_DB,,}" ]; then
  echo "ycsb run $LOC: "${SRCDB_ARC_USER}" != "${SRCDB_DB} skipping
  exit
fi

# start the YCSB
case "${SRCDB_GRP,,}" in
  mysql|postgresql|sqlserver|informix|oracle)
    ycsb_run_src
;;
  mongodb)
    pushd ${YCSB}/*mongodb*/  
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
