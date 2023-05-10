#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# ycsb data population 
banner ycsb 

usertable_cnt=$(mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -sN -e 'select count(*) from usertable;' | tail -1)
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    pushd ${YCSB}/*jdbc*/ >/dev/null
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.mariadb.jdbc.Driver -p db.url="jdbc:mariadb://${SRCDB_HOST}/${SRCDB_ARC_USER}?rewriteBatchedStatements=true&permitMysqlScheme&restrictedAuth=mysql_native_password" -p db.user=${SRCDB_ARC_USER} -p db.passwd=${SRCDB_ARC_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000 
    popd >/dev/null
else
  echo "Info: ${usertable_cnt} rows exist. skipping" 
fi
mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose -e 'select count(*) from usertable; desc usertable;select * from usertable limit 1' 