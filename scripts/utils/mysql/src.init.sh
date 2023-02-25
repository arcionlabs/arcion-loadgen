#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
ping_db () {
  local db_host=$1
  local db_user=$2
  local db_pw=$3
  local db_port=${4:-3306}
  rc=1
  while [ ${rc} != 0 ]; do
    mysql -h${db_host} -u${db_user} -p${db_pw} -e "show databases; status;" --verbose 
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${db_host} as ${db_user} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
ping_db "${SRCDB_HOST}" "${SRCDB_ROOT}" "${SRCDB_PW}" "${SRCDB_PORT}"

# setup database permissions
banner src root
for f in ${CFG_DIR}/src.init.root.*sql; do
  echo "cat $f | envsubst | mysql --force -h${SRCDB_HOST} -u${SRCDB_ROOT} -p${SRCDB_PW} --verbose"
  cat $f | envsubst | mysql --force -h${SRCDB_HOST} -u${SRCDB_ROOT} -p${SRCDB_PW} --verbose 
done

banner src user
for f in ${CFG_DIR}/src.init.user.*sql; do
  echo "cat $f | envsubst | mysql --force -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose" 
  cat $f | envsubst | mysql --force -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose 
done

# sysbench data population
banner sysbench 

sbtest1_cnt=$(mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -sN -e 'select count(*) from sbtest1;' )

if [[ ${sbtest1_cnt} == "0" ]]; then
  # on existing table, create new rows
  sysbench oltp_read_write --skip_table_create=on --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
elif [[ ${sbtest1_cnt} == "" ]]; then
  # create default table with new rows  
  sysbench oltp_read_write --mysql-host=${SRCDB_HOST} --auto_inc=off --db-driver=mysql --mysql-user=${SRCDB_ARC_USER} --mysql-password=${SRCDB_ARC_PW} --mysql-db=${SRCDB_ARC_USER} prepare 
else
  echo "Info: ${sbtest1_cnt} rows exist. skipping"  
fi
mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose -e 'select count(*) from sbtest1; select sum(k) from sbtest1;desc sbtest1;select * from sbtest1 limit 1' 

# ycsb data population 
banner ycsb 

usertable_cnt=$(mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} -sN -e 'select count(*) from usertable;' | tail -1)
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    pushd ${YCSB}/*jdbc*/
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.mariadb.jdbc.Driver -p db.url="jdbc:mariadb://${SRCDB_HOST}/${SRCDB_ARC_USER}?rewriteBatchedStatements=true&permitMysqlScheme&restrictedAuth=mysql_native_password" -p db.user=${SRCDB_ARC_USER} -p db.passwd=${SRCDB_ARC_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000 
    popd
else
  echo "Info: ${usertable_cnt} rows exist. skipping" 
fi
mysql -h${SRCDB_HOST} -u${SRCDB_ARC_USER} -p${SRCDB_ARC_PW} -D${SRCDB_ARC_USER} --verbose -e 'select count(*) from usertable; desc usertable;select * from usertable limit 1' 