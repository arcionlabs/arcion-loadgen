#!/usr/bin/env bash

if [ -z "${SRCDB_HOST}" ]; then echo "SRCDB_HOST=xxx src.init.sh"; exit 1; fi
if [ -z "${SRCDB_TYPE}" ]; then echo "SRCDB_TYPE=xxx src.init.sh"; exit 1; fi

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-root}
MYSQL_ROOT_PW=${MYSQL_ROOT_PW:-password}

PG_ROOT_USER=${PG_ROOT_USER:-postgres}
PG_ROOT_PW=${PG_ROOT_PW:-password}

ARCSRC_USER=${ARCSRC_USER:-arcsrc}
ARCSRC_PW=${ARCSRC_PW:-password}

ARCDST_USER=${ARCDST_USER:-arcdst}
ARCDST_PW=${ARCDST_PW:-password}

wait_pg () {
  local host=$1
  local user=${2:-postgres}
  local pw=${3:-password}
  local port=${4:-5432}
  rc=1
  while [ ${rc} != 0 ]; do
    psql -l postgresql://${user}:${pw}@${host}:${port}/ >/dev/null 2>&1
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${host} as ${user} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
wait_pg ${SRCDB_HOST} ${PG_ROOT_USER} ${PG_ROOT_PW}

# setup database permissions
banner src root

cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sql | psql postgresql://${PG_ROOT_USER}:${PG_ROOT_PW}@${SRCDB_HOST}

banner src user

cat ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.arcsrc.sql | psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST}/${ARCSRC_USER}

# sysbench data population
banner sysbench 

sbtest1_cnt=$(psql --csv -t postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST} <<EOF
select count(*) from sbtest1; 
EOF
)

if [[ ${sbtest1_cnt} == "0" ]]; then
  echo "Empty table exists. adding new rows"
  sysbench oltp_read_write --skip_table_create=on --pgsql-host=${SRCDB_HOST} --auto_inc=off --db-driver=pgsql --pgsql-user=${ARCSRC_USER} --pgsql-password=${ARCSRC_PW} --pgsql-db=${ARCSRC_USER} prepare 
elif [[ ${sbtest1_cnt} == "" ]]; then
  echo "Creating default table with new rows"
  sysbench oltp_read_write --pgsql-host=${SRCDB_HOST} --auto_inc=off --db-driver=pgsql --pgsql-user=${ARCSRC_USER} --pgsql-password=${ARCSRC_PW} --pgsql-db=${ARCSRC_USER} prepare 
else
  echo "Rows exist. skipping adding new rows"
fi

psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST} <<EOF
select count(*) from sbtest1; 
select sum(k) from sbtest1;
select * from sbtest1 limit 1;
EOF

# ycsb data population 
banner ycsb 

usertable_cnt=$(psql --csv -t postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST} <<EOF
select count(*) from usertable; 
EOF
)

pushd ${YCSB}
if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    bin/ycsb.sh load jdbc -s -P workloads/workloada -p db.driver=org.postgresql.Driver  -p db.url="jdbc:postgresql://${SRCDB_HOST}/${ARCSRC_USER}?reWriteBatchedInserts=true" -p db.user=${ARCSRC_USER} -p db.passwd=${ARCSRC_PW} -p db.batchsize=1000  -p jdbc.fetchsize=10 -p jdbc.autocommit=true -p jdbc.batchupdateapi=true -p db.batchsize=1000 -p recordcount=10000
fi

psql postgresql://${ARCSRC_USER}:${ARCSRC_PW}@${SRCDB_HOST} <<EOF
select count(*) from usertable; 
select * from usertable limit 1;
EOF

popd