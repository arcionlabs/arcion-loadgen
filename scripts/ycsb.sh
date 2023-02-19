#!/usr/bin/env bash

RATE=${1:-1}
THREADS=${2:-1}

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/ini_jdbc.sh
echo $SRC_JDBC_DRIVER
echo $SRC_JDBC_URL

# start the YCSB

case "${SRCDB_GRP,,}" in
  mysql|postgresql)
    pushd ${YCSB}/*jdbc*/  
    bin/ycsb.sh run jdbc -s -threads ${THREADS} -target ${RATE} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((10000*$THREADS)) \
    -p db.driver=${SRC_JDBC_DRIVER} \
    -p db.url="${SRC_JDBC_URL}" \
    -p db.user=${SRCDB_ARC_USER} \
    -p db.passwd="${SRCDB_ARC_PW}" \
    -p db.batchsize=1000  \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=true \
    -p db.batchsize=1000
    popd  
;;
  mongodb)
    pushd ${YCSB}/*mongodb*/  
    bin/ycsb.sh load mongodb -s -threads ${THREADS} -target ${RATE} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((10000*$THREADS)) \
    -p mongodb.url="${SRC_JDBC_URL}"
    popd  
    ;; 
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support"
    ;;
esac 
