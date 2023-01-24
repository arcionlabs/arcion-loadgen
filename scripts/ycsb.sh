#!/usr/bin/env bash

RATE=${1:-1}
THREADS=${1:-1}

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
# get the jdbc driver to match
. ${SCRIPTS_DIR}/ini_jdbc.sh
echo $JDBC_DRIVER
echo $JDBC_URL

# start the YCSB
YCSB=${YCSB:-/opt/ycsb-0.17.0-jdbc-binding}

pushd ${YCSB}

bin/ycsb.sh run jdbc -s -threads ${THREADS} -target ${RATE} \
-P workloads/workloada \
-p requestdistribution=uniform \
-p readproportion=0 \
-p db.driver=${JDBC_DRIVER} \
-p db.url="${JDBC_URL}" \
-p db.user=${SRCDB_ARC_USER} \
-p db.passwd="${SRCDB_ARC_PW}" \
-p db.batchsize=1000  \
-p jdbc.fetchsize=10 \
-p jdbc.autocommit=true \
-p db.batchsize=1000 \
-p recordcount=10000 \
-p operationcount=$((10000*$THREADS)) 

popd
