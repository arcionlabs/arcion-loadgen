#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
ping_db () {
  rc=1
  while [ ${rc} != 0 ]; do
    echo '\databases' | ${JSQSH_DIR}/*/bin/jsqsh --driver="${DSTDB_JSQSH_DRIVER}" --user="${DSTDB_ROOT}" --password="${DSTDB_PW}" --server="${DSTDB_HOST}" --port="${DSTDB_PORT}"
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${DSTDB_HOST} as ${DSTDB_ARC_USER} to connect"
      sleep 10
    fi
  done
}

# wait for src db to be ready to connect
ping_db

# setup database permissions
banner dst root

for f in ${CFG_DIR}/dst.init.root.*sql; do
  cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${DSTDB_JSQSH_DRIVER}" --user="${DSTDB_ROOT}" --password="${DSTDB_PW}" --server="${DSTDB_HOST}" --port="${DSTDB_PORT}"
done

banner dst user

for f in ${CFG_DIR}/dst.init.user.*sql; do
  cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${DSTDB_JSQSH_DRIVER}" --user="${DSTDB_ARC_USER}" --password="${DSTDB_ARC_PW}" --server="${DSTDB_HOST}" --port="${DSTDB_PORT}" --database="${DSTDB_ARC_USER}"
done