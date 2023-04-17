#!/usr/bin/env bash

. $SCRIPTS_DIR/lib/ycsb_jdbc.sh
. $SCRIPTS_DIR/lib/ping_utils.sh

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# wait for src db to be ready to connect
declare -A EXISTING_DBS
ping_db EXISTING_DBS "${SRCDB_HOST}" "${SRCDB_PORT}" "${SRCDB_JSQSH_DRIVER}" "${SRCDB_ARC_USER}" "${SRCDB_ARC_PW}" "${SRCDB_DB}"

# setup database permissions
if [ -z "${EXISTING_DBS[${SRCDB_DB}]}" ]; then
  echo "src db ${SRCDB_ROOT}: ${SRCDB_DB} setup"
  for f in ${CFG_DIR}/src.init.root.*sql; do
    cat ${f} | jsqsh --driver="${SRCDB_JSQSH_DRIVER}" --user="${SRCDB_ROOT}" --password="${SRCDB_PW}" --server="${SRCDB_HOST}" --port=${SRCDB_PORT} --database="${SRCDB_ROOT_DB}"
  done
else
  echo "src db ${SRCDB_DB} already setup. skipping db setup"
fi

if [ 1 ]; then # || [ "${SRCDB_DB}" = "${SRCDB_ARC_USER}" ]; then
  echo "src db ${SRCDB_ARC_USER}: ${SRCDB_DB} setup"

  for f in ${CFG_DIR}/src.init.user.*sql; do
    cat ${f} | jsqsh --driver="${SRCDB_JSQSH_DRIVER}" --user="${SRCDB_ARC_USER}" --password="${SRCDB_ARC_PW}" --server="${SRCDB_HOST}" --port=${SRCDB_PORT} --database="${SRCDB_DB}"
  done
else
  echo "src db ${SRCDB_ARC_USER} != ${SRCDB_DB} skipping user setup"
fi

# setup workloads
if [ 1 ]; then # || [ "${SRCDB_DB}" = "${SRCDB_ARC_USER}" ]; then
  echo "src db ${SRCDB_ARC_USER}: benchbase setup"
  # benchbase data population
  ${SCRIPTS_DIR}/bin/benchbase-load.sh

  # ycsb data population 
  echo "src db ${SRCDB_ARC_USER}: ycsb setup"
  ycsb_load_src
fi
