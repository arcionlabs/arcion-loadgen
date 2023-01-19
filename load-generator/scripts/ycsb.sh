#!/usr/bin/env bash

local THREADS=${1:-1} 

YCSB=${YCSB:-/opt/ycsb-0.17.0-jdbc-binding}

pushd ${YCSB}

bin/ycsb.sh run jdbc -s -threads ${THREADS} \
-P workloads/workloada \
-p db.driver=com.mysql.jdbc.Driver \
-p db.url="jdbc:mysql://${SRCDB_HOST}/arcion" \
-p db.user=arcion \
-p db.passwd="password" \
-p db.batchsize=1000  \
-p jdbc.fetchsize=10 \
-p jdbc.autocommit=true \
-p db.batchsize=1000 \
-p recordcount=10000 \
-p operationcount=$((10000*$THREADS)) 

popd