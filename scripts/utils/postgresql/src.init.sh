#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh

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
  cat ${f} | envsubst | psql --echo-all postgresql://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_DB} 
done

# benchbase data population
banner benchbase
${SCRIPTS_DIR}/bin/benchbase-load.sh

# ycsb data population 
banner ycsb 
ycsb_load_src
