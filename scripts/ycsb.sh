#!/usr/bin/env bash

RATE=${1:-1}
THREADS=${1:-1}

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

YCSB=${YCSB:-/opt/ycsb-0.17.0-jdbc-binding}

pushd ${YCSB}

bin/ycsb.sh run jdbc -s -threads ${THREADS} -target ${RATE} \
-P workloads/workloada \
-p requestdistribution=uniform \
-p readproportion=0 \
-p db.driver=org.mariadb.jdbc.Driver \
-p db.url="jdbc:mariadb://${SRCDB_HOST}/${SRCDB_ARC_USER}?permitMysqlScheme&restrictedAuth=mysql_native_password" \
-p db.user=${SRCDB_ARC_USER} \
-p db.passwd="${SRCDB_ARC_PW}" \
-p db.batchsize=1000  \
-p jdbc.fetchsize=10 \
-p jdbc.autocommit=true \
-p db.batchsize=1000 \
-p recordcount=10000 \
-p operationcount=$((10000*$THREADS)) 

popd
