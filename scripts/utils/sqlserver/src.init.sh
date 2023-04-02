#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
ping_db () {
  rc=1
  while [ ${rc} != 0 ]; do
    echo '\databases' | ${JSQSH_DIR}/*/bin/jsqsh --driver="${SRCDB_JSQSH_DRIVER}" --user="${SRCDB_ROOT}" --password="${SRCDB_PW}" --server="${SRCDB_HOST}" --port="${SRCDB_PORT}"
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${SRCDB_HOST} as ${SRCDB_ROOT} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
ping_db

# setup database permissions
banner src root

for f in ${CFG_DIR}/src.init.root.*sql; do
  cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${SRCDB_JSQSH_DRIVER}" --user="${SRCDB_ROOT}" --password="${SRCDB_PW}" --server="${SRCDB_HOST}" --port="${SRCDB_PORT}"
done

banner src user

for f in ${CFG_DIR}/src.init.user.*sql; do
  cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${SRCDB_JSQSH_DRIVER}" --user="${SRCDB_ARC_USER}" --password="${SRCDB_ARC_PW}" --server="${SRCDB_HOST}" --port="${SRCDB_PORT}" --database="${SRCDB_DB}"
done

# benchbase data population
banner benchbase
${SCRIPTS_DIR}/bin/benchbase-load.sh

# ycsb data population 
banner ycsb 
ycsb_load_src
