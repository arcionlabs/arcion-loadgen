#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

# util functions
ping_db () {
  local db_host=$1
  local db_user=$2
  local db_pw=$3
  local db_port=${4:-3306}
  rc=1
  while [ ${rc} != 0 ]; do
    mysql -h${db_host} -u${db_user} -p${db_pw} -e "show databases; status;" --verbose 
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
for f in ${CFG_DIR}/dst.init.root.*sql; do
    echo "cat $f | envsubst | mysql --force -h${DSTDB_HOST} -u${DSTDB_ROOT} -p${DSTDB_PW} --verbose "
    cat $f | envsubst | mysql --force -h${DSTDB_HOST} -u${DSTDB_ROOT} -p${DSTDB_PW} --verbose 
done

# with the arcsrc user
for f in ${CFG_DIR}/dst.init.user.*sql; do
    echo "cat $f | envsubst | mysql --force -h${DSTDB_HOST} -u${DSTDB_ARC_USER} -p${DSTDB_ARC_PW} -D${DSTDB_ARC_USER} --verbose"
    cat $f | envsubst | mysql --force -h${DSTDB_HOST} -u${DSTDB_ARC_USER} -p${DSTDB_ARC_PW} -D${DSTDB_ARC_USER} --verbose
done