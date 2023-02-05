#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

DSTDB_ROOT=${DSTDB_ROOT:-postgres}
DSTDB_PW=${DSTDB_PW:-password}
DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcsrc}
DSTDB_ARC_PW=${DSTDB_ARC_PW:-password}
DSTDB_PORT=${DSTDB_PORT:-5432}

# util functions
ping_db () {
  local db_host=$1
  local db_user=$2
  local db_pw=$3
  local db_port=${4:-5432}
  rc=1
  while [ ${rc} != 0 ]; do
    echo '\d' | psql postgresql://${db_user}:${db_pw}@${db_host}:${db_port}/  2>&1 | tee -a $CFG_DIR/src.init.sh.log
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${db_host} as ${db_user} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
ping_db "${DSTDB_HOST}" "${DSTDB_ROOT}" "${DSTDB_PW}" "${DSTDB_PORT}"

# with root user
if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql ]; then
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sql | psql --echo-all postgresql://${DSTDB_ROOT}:${DSTDB_PW}@${DSTDB_HOST}:${DSTDB_PORT}/ 2>&1 | tee -a $CFG_DIR/dst.init.sh.log
fi

# with the arcdst user
if [ -f ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcdst.sql ]; then
    cat ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.arcdst.sql | psql --echo-all postgresql://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER} 2>&1 | tee -a $CFG_DIR/dst.init.sh.log
fi