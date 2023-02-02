#!/usr/bin/env bash

if [ -z "${SRCDB_HOST}" ]; then echo "SRCDB_HOST=xxx src.init.sh"; exit 1; fi
if [ -z "${SRCDB_TYPE}" ]; then echo "SRCDB_TYPE=xxx src.init.sh"; exit 1; fi

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

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
wait_mysql "${SRCDB_HOST}" "${SRCDB_ROOT}" "${SRCDB_PW}"

# setup database permissions
banner source

cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sql | mysql -h${SRCDB_HOST} -u${SRCDB_ROOT} -p${SRCDB_PW} --verbose
cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.arcsrc.sql | mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose

# sysbench data population
banner sysbench 

sbtest1_cnt=$(mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -sN -e 'select count(*) from sbtest1;' 2>/dev/null | tail -1)
if [[ ${sbtest1_cnt} == "0" ]]; then
  sysbench oltp_read_write --skip_table_create=on --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
else
  sysbench oltp_read_write --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
fi
mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose -e 'select count(*) from sbtest1; select sum(k) from sbtest1;desc sbtest1;select * from sbtest1 limit 1'

# ycsb data population 
banner ycsb 

usertable_cnt=$(mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -sN -e 'select count(*) from usertable;' | tail -1)
pushd ${YCSB}
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.mariadb.jdbc.Driver -p db.url="jdbc:mariadb://${SRCDB_HOST}/${SRCDB_ARC_USER}?rewriteBatchedStatements=true&permitMysqlScheme&restrictedAuth=mysql_native_password" -p db.user=${SRCDB_ARC_USER} -p db.passwd=${SRCDB_ARC_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000
fi
mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose -e 'select count(*) from usertable; desc usertable;select * from usertable limit 1'
popd