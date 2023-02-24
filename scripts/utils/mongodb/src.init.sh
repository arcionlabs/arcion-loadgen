#!/usr/bin/env bash

# should be set by menu.sh before coming here
[ -z "${LOG_ID}" ] && LOG_DIR="$$" && echo "Warning: LOG_DIR assumed"
[ -z "${CFG_DIR}" ] && CFG_DIR="/tmp/arcion/${LOG_ID}" && echo "Warning: CFG_DIR assumed"

SRCDB_ROOT=${SRCDB_ROOT:-root}
SRCDB_PW=${SRCDB_PW:-password}
SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}
SRCDB_PORT=${SRCDB_PORT:-27017}

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

SRCDB_ROOT_URL="mongodb://${SRCDB_ROOT}:${SRCDB_PW}@${SRCDB_HOST}:${SRCDB_PORT}/"

SRCDB_ARC_USER_URL="mongodb://${SRCDB_ARC_USER}:${SRCDB_ARC_PW}@${SRCDB_HOST}:${SRCDB_PORT}/${SRCDB_ARC_USER}"

# wait for src db to be ready to connect
ping_db "${SRCDB_ROOT_URL}" 

# setup database permissions
banner src root

for f in ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.root.*js; do
  echo "cat $f | envsubst | mongosh ${SRCDB_ROOT_URL}"
  cat $f | envsubst | mongosh ${SRCDB_ROOT_URL} 
done

banner src user

for f in ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.user.*js; do
  echo "cat $f | envsubst | mongosh ${SRCDB_ARC_USER_URL}"
  cat $f | envsubst | mongosh ${SRCDB_ARC_USER_URL} 
done

# sysbench data population
banner sysbench 

sbtest1_cnt=$( mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.sbtest1.countDocuments()' )

if [[ ${sbtest1_cnt} == "0" ]]; then
  # on existing table, create new rows
  echo "TBD"
elif [[ ${sbtest1_cnt} == "" ]]; then
  # create default table with new rows  
  echo "TBD"
else
  echo "Info: ${sbtest1_cnt} rows exist. skipping" 
fi
mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.sbtest1.countDocuments()' 
mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.sbtest1.find().count(1)' 

# ycsb data population 
banner ycsb 

usertable_cnt=$(mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.usertable.countDocuments()' )

if [[ ${usertable_cnt} == "0" || ${usertable_cnt} == "" ]]; then
    pushd ${YCSB}/*mongodb*/
    bin/ycsb.sh load mongodb -s -P workloads/workloada -p mongodb.url="${SRCDB_ARC_USER_URL}?w=0"  -p recordcount=10000 
    popd
else
  echo "Info: ${usertable_cnt} rows exist. skipping"
fi
mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.usertable.countDocuments()' 
mongosh $SRCDB_ARC_USER_URL --quiet --eval 'db.usertable.find().count(1)' 