#!/usr/bin/env bash

MYSQL_HOST=${MYSQL_HOST:-mysql1}
SCRIPT_DIR=${SCRIPT_DIR:-/}

# wait for mysql
rc=1
while [ ${rc} != 0 ]; do
  mysql -h${MYSQL_HOST} -uroot -ppassword -e "show databases"
  rc=$?
  if (( ${rc} != 0 )); then
    echo "waiting 10 sec for mysql to connect"
    sleep 10
  fi
done

# setup database permissions
banner mysql

cat ${SCRIPT_DIR}/scripts/mysql.init.arcion.sql | mysql -h${MYSQL_HOST} -uroot -ppassword --verbose
cat ${SCRIPT_DIR}/scripts/mysql.init.sysbench.sql | mysql -h${MYSQL_HOST} -uroot -ppassword --verbose
cat ${SCRIPT_DIR}/scripts/mysql.init.ycsb.sql | mysql -h${MYSQL_HOST} -uroot -ppassword --verbose

# sysbench data population
banner sysbench 
sbtest1_cnt=$(mysql -h${MYSQL_HOST} -usbt -ppassword -Dsbt -sN -e 'select count(*) from sbtest1;' | tail -1)
if [[ ${sbtest1_cnt} == "0" || ${sbtest1_cnt} == "" ]]; then
  sysbench oltp_read_write --mysql-host=mysql1 --auto_inc=off --db-driver=mysql --mysql-user=sbt --mysql-password=password --mysql-db=sbt prepare 
fi
mysql -h${MYSQL_HOST} -usbt -ppassword -Dsbt --verbose -e 'select count(*) from sbtest1; select sum(k) from sbtest1;desc sbtest1;select * from sbtest1 limit 1'

# ycsb data population 
banner ycsb 
usertable_cnt=$(mysql -h${MYSQL_HOST} -uycsb -ppassword -Dycsb -sN -e 'select count(*) from usertable;' | tail -1)
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=com.mysql.jdbc.Driver -p db.url="jdbc:mysql://${MYSQL_HOST}/ycsb?rewriteBatchedStatements=true" -p db.user=ycsb -p db.passwd="password" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000
fi
mysql -h${MYSQL_HOST} -uycsb -ppassword -Dycsb --verbose -e 'select count(*) from usertable; desc usertable;select * from usertable limit 1'
