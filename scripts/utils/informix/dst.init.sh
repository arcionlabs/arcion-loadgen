#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# wait for src db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS ${DSTDB_HOST} ${DSTDB_PORT} ${DSTDB_JSQSH_DRIVER} ${DSTDB_ROOT} ${DSTDB_PW}

# setup database permissions
if [ -z "${EXISTING_DBS[${DSTDB_DB}]}" ]; then
  banner src root
  for f in ${CFG_DIR}/src.init.root.*sql; do
    cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${DSTDB_JSQSH_DRIVER}" --user="${DSTDB_ROOT}" --password="${DSTDB_PW}" --server="${DSTDB_HOST}" --port="${DSTDB_PORT}"
  done

  banner src user
  for f in ${CFG_DIR}/src.init.user.*sql; do
    cat ${f} | envsubst | ${JSQSH_DIR}/*/bin/jsqsh --driver="${DSTDB_JSQSH_DRIVER}" --user="${DSTDB_ARC_USER}" --password="${DSTDB_ARC_PW}" --server="${DSTDB_HOST}" --port="${DSTDB_PORT}" --database="${DSTDB_DB}"
  done
else
  echo "dst db ${DSTDB_DB} already setup. skipping db setup"
fi

