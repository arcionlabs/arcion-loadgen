#!/usr/bin/env bash
YCSB=${YCSB:-/opt/ycsb-0.17.0-jdbc-binding}

pushd ${YCSB}

bin/ycsb.sh run jdbc -s -P workloads/workloada \
-p db.driver=com.mysql.jdbc.Driver \
-p db.url="jdbc:mysql://${MYSQL_HOST}/ycsb" \
-p db.user=ycsb \
-p db.passwd="password" \
-p db.batchsize=1000  \
-p jdbc.fetchsize=10 \
-p jdbc.autocommit=true \
-p db.batchsize=1000 \
-p recordcount=10000 \
-p operationcount=10000

popd