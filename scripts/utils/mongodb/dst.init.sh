#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
ping_db () {
  local db_url=$1
  rc=1
  while [ ${rc} != 0 ]; do
    mongosh $db_url --quiet --eval "db.getCollectionInfos()" --verbose 
    rc=$?
    if (( ${rc} != 0 )); then
      echo "waiting 10 sec for ${url} to connect"
      sleep 10
    fi
  done
}

DSTDB_ROOT_URL="mongodb://${DSTDB_ROOT}:${DSTDB_PW}@${DSTDB_HOST}:${DSTDB_PORT}/"

DSTDB_USER_URL="mongodb://${DSTDB_ARC_USER}:${DSTDB_ARC_PW}@${DSTDB_HOST}:${DSTDB_PORT}/${DSTDB_ARC_USER}"

# wait for dst db to be ready to connect
ping_db "${DSTDB_ROOT_URL}" 

# setup database permissions
banner dst root

for f in ${CFG_DIR}/dst.init.root.*js; do 
  echo "cat $f | envsubst | mongosh ${DSTDB_ROOT_URL}"
  cat $f | envsubst | mongosh ${DSTDB_ROOT_URL} 
done  

banner dst user

for f in ${CFG_DIR}/dst.init.user.*js; do
  echo "cat $f | envsubst | mongosh ${DSTDB_USER_URL}"
  cat $f | envsubst | mongosh ${DSTDB_USER_URL} 
done