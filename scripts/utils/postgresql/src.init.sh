#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

SRCDB_ROOT=${SRCDB_ROOT:-postgres}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}
SRCDB_PORT=${SRCDB_PORT:-5432}

# util functions
ping_db () {
  local db_host=$1
  local db_user=$2
  local db_pw=$3
  local db_port=${4:-5432}
  rc=1
  while [ ${rc} != 0 ]; do
    echo '\d' | psql postgresql://${db_user}:${db_pw}@${db_host}:${db_port}/
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
  cat ${f} | envsubst | psql --echo-all postgresql://${SRCDB_ROOT}:${SRCDB_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ROOT} 
done

banner src user

for f in ${CFG_DIR}/src.init.user.*sql; do
  cat ${f} | envsubst | psql --echo-all postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} 
done

# sysbench data population
banner sysbench 

sbtest1_cnt=$(echo 'select count(*) from sbtest1;' | psql --csv -t postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} )

if [[ ${sbtest1_cnt} == "0" ]]; then
  # on existing table, create new rows
  sysbench oltp_read_write --skip_table_create=on --pgsql-host=${SRCDB_HOST} --auto_inc=off --db-driver=pgsql --pgsql-user=${SRCDB_ARC_USER} --pgsql-password=${SRCDB_ARC_PW} --pgsql-db=${SRCDB_ARC_USER} --pgsql-port=${SRCDB_PORT} prepare 
elif [[ ${sbtest1_cnt} == "" ]]; then
  # create default table with new rows  
  sysbench oltp_read_write --pgsql-host=${SRCDB_HOST} --auto_inc=off --db-driver=pgsql --pgsql-user=${SRCDB_ARC_USER} --pgsql-password=${SRCDB_ARC_PW} --pgsql-db=${SRCDB_ARC_USER} --pgsql-port=${SRCDB_PORT}  prepare 
else
  echo "Info: sbtest1 ${sbtest1_cnt} rows exist. skipping"  
fi

cat <<EOF | psql postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} 
select count(*) from sbtest1; 
select sum(k) from sbtest1;
select * from sbtest1 limit 1;
EOF

# ycsb data population 
banner ycsb 

usertable_cnt=$(echo 'select count(*) from usertable;' | psql --csv -t postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} )

if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    pushd ${YCSB}/*jdbc*/
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver  -p db.url="jdbc:postgresql://${SRCDB_HOST}:${SRCDB_PORT}/${ARCSRC_USER}?sslmode=disable&reWriteBatchedInserts=true" -p db.user=${SRCDB_ARC_USER} -p db.passwd="${SRCDB_ARC_PW}" -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000 
    popd
else
  echo "Info: usertable ${usertable_cnt} rows exist. skipping" 
fi
cat <<EOF | psql postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER} 
select count(*) from usertable; 
select * from usertable limit 1;
EOF