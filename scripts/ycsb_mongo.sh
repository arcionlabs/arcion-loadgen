#!/usr/bin/env bash

. lib/job_control.sh


ycsb_shell() {
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local HOST="${1-${SRCDB_HOST}}"  
  local USER="${2:-${SRCDB_ARC_USER}}"
  local PW="${3:-${SRCDB_ARC_PW}}"
  local port="${4:-${SRCDB_PORT}}"
  local jdbc_url="${5:-${SRCDB_JDBC_URL}}"
  local jdbc_driver="${6:-${SRCDB_JDBC_DRIVER}}"

  bin/ycsb.sh shell jdbc \
  -p db.driver="${jdbc_driver}" \
  -p db.url="${jdbc_url}" \
  -p db.user="${USER}" \
  -p db.passwd="${PW}" \
  -P workloads/workloada \
  -p requestdistribution=uniform \
  -p insertorder=ordered
}

ycsb_create() {
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  # does not work with MySQL
  local HOST="${1-${SRCDB_HOST}}"  
  local USER="${2:-${SRCDB_ARC_USER}}"
  local PW="${3:-${SRCDB_ARC_PW}}"
  local port="${4:-${SRCDB_PORT}}"
  local jdbc_url="${5:-${SRCDB_JDBC_URL}}"
  local jdbc_driver="${6:-${SRCDB_JDBC_DRIVER}}"

  ${JSQSH_DIR}/*/bin/jsqsh --driver="mysql" --user="${USER}" --password="${PW}" --server="${HOST}" --port="${port}" --database="${USER}"
}

ycsb_load() { 
# https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local HOST="${1-${SRCDB_HOST}}"  
  local USER="${2:-${SRCDB_ARC_USER}}"
  local PW="${3:-${SRCDB_ARC_PW}}"
  local port="${4:-${SRCDB_PORT}}"
  local jdbc_url="${5:-${SRCDB_JDBC_URL}}"
  local jdbc_driver="${6:-${SRCDB_JDBC_DRIVER}}"
  local THREADS=${THREADS:-$(getconf _NPROCESSORS_ONLN)}
  local ycsb_recordcount=${ycsb_recordcount:-10000}

  jdbc_url=${jdbc_url}&rewriteBatchedStatements=true

  ${YCSB}/*jdbc*/bin/ycsb.sh load jdbc -s -threads ${THREADS} \
  -p workload=site.ycsb.workloads.CoreWorkload \
  -p db.driver="${jdbc_driver}" \
  -p db.url="${jdbc_url}" \
  -p db.user=${USER} \
  -p db.passwd=${PW} \
  -p db.batchsize=1000  \
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p jdbc.batchupdateapi=true \
  -p recordcount=${ycsb_recordcount} \
  -p requestdistribution=uniform \
  -p insertorder=ordered
}

ycsb_run() {
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local HOST="${1-${SRCDB_HOST}}"  
  local USER="${2:-${SRCDB_ARC_USER}}"
  local PW="${3:-${SRCDB_ARC_PW}}"
  local port="${4:-${SRCDB_PORT}}"
  local jdbc_url="${5:-${SRCDB_JDBC_URL}}"
  local jdbc_driver="${6:-${SRCDB_JDBC_DRIVER}}"

  local ycsb_threads=${ycsb_threads:-1}
  local ycsb_rate=${ycsb_rate:-1}
  local ycsb_timer=${ycsb_timer:-30}
  local ycsb_recordcount=${ycsb_recordcount:-10000}
  local ycsb_insertstart=${ycsb_insertstart:-0}
  local ycsb_operationcount=${ycsb_operationcount:-$((${ycsb_recordcount}*${ycsb_threads}*${ycsb_timer}))}

  ${YCSB}/*jdbc*/bin/ycsb.sh run jdbc -s -threads ${ycsb_threads} -target ${ycsb_rate} \
  -p updateproportion=1 \
  -p readproportion=0 \
  -p workload=site.ycsb.workloads.CoreWorkload \
  -p requestdistribution=uniform \
  -p recordcount=${ycsb_recordcount} \
  -p insertstart=${ycsb_insertstart} \
  -p operationcount=${ycsb_operationcount} \
  -p db.driver=${jdbc_driver} \
  -p db.url="${jdbc_url}" \
  -p db.user=${USER} \
  -p db.passwd="${PW}" \
  -p db.batchsize=1000  \
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p requestdistribution=uniform \
  -p insertorder=ordered &    
  # save the PID  
  export YCSB_RUN_PID="$!"
  # wait 
  if (( ycsb_timer != 0 )); then
    wait_jobs "$YCSB_RUN_PID" "${ycsb_timer}"
  fi
}
