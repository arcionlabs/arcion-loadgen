#!/usr/bin/env bash

export SCRIPT_DIR=${SCRIPT_DIR:-/}

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
DSTDB_ROOT=${DSTDB_ROOT:-root}
DSTDB_PW=${DSTDB_PW:-password}

# YCSB install dir
YCSB=${YCSB:-/opt/ycsb-0.17.0-jdbc-binding}

# default creating YCSB, SBT
YCSB_DB=arcion
YCSB_USER=arcion
YCSB_PW=password
SBT_DB=arcion
SBT_USER=arcion
SBT_PW=password

# util functions
wait_mysql () {
  local srcdb_host=$1
  local srcdb_root=$2
  local srcdb_pw=$3
  local srcdb_port=${4:-3306}
  rc=1
  while [ ${rc} != 0 ]; do
    mysql -h${srcdb_host} -u${srcdb_root} -p${srcdb_pw} -e "show databases"
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${srcdb_host} as ${srcdb_root} to connect"
      sleep 10
    fi
  done
}
# wait for src db to be ready to connect
wait_mysql ${SRCDB_HOST} ${SRCDB_ROOT} ${SRCDB_PW}
wait_mysql ${DSTDB_HOST} ${DSTDB_ROOT} ${DSTDB_PW}

# setup database permissions
banner mysql

cat ${SCRIPT_DIR}/scripts/mysql.config.sql | mysql -h${SRCDB_HOST} -u${SRCDB_ROOT} -p${SRCDB_PW} --verbose
cat ${SCRIPT_DIR}/scripts/mysql.init.sysbench.sql | mysql -h${SRCDB_HOST} -u${SBT_USER} -p${SBT_PW} -D${SBT_DB} --verbose
cat ${SCRIPT_DIR}/scripts/mysql.init.ycsb.sql | mysql -h${SRCDB_HOST} -u${YCSB_USER} -p${YCSB_PW} -D${YCSB_DB} --verbose

# sysbench data population
banner sysbench 

sbtest1_cnt=$(mysql -h${SRCDB_HOST} -u${SBT_USER} -p${SBT_PW} -D${SBT_DB} -sN -e 'select count(*) from sbtest1;' | tail -1)
if [[ ${sbtest1_cnt} == "0" || ${sbtest1_cnt} == "" ]]; then
  sysbench oltp_read_write --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SBT_USER} --mysql-password=${SBT_PW} --mysql-db=${SBT_DB} prepare 
fi
mysql -h${SRCDB_HOST} -u${SBT_USER} -p${SBT_PW} -D${SBT_DB} --verbose -e 'select count(*) from sbtest1; select sum(k) from sbtest1;desc sbtest1;select * from sbtest1 limit 1'

# ycsb data population 
banner ycsb 

usertable_cnt=$(mysql -h${SRCDB_HOST} -u${YCSB_USER} -p${YCSB_PW} -D${YCSB_DB} -sN -e 'select count(*) from usertable;' | tail -1)
pushd ${YCSB}
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://${SRCDB_HOST}/${YCSB_DB}?rewriteBatchedStatements=true" -p db.user=${YCSB_USER} -p db.passwd=${YCSB_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000
fi
mysql -h${SRCDB_HOST} -u${YCSB_USER} -p${YCSB_PW} -D${YCSB_DB} --verbose -e 'select count(*) from usertable; desc usertable;select * from usertable limit 1'
popd