#!/usr/bin/env bash

kill_recurse() {
    cpids=`pgrep -P $1|xargs`
    for cpid in $cpids;
    do
        kill_recurse $cpid
    done
    echo "killing $1"
    kill -9 $1
}

kill_jobs() {
  for pid in $(jobs -p); do
    # kill -2 kills parent and the child
    echo kill_recurse $pid
    kill_recurse $pid
  done
}

wait_jobs() {
  local PIDS="$1"
  local TIMER="${2:-30}"
  local JOBS_CNT=1
  local waited_sec=0

  # allow ctl-c to kill background jobs
  trap kill_jobs SIGINT

  while (( JOBS_CNT != 0 )); do
    JOBS_CNT=0
    # wait for all background jobs if not specified
    if [ -z "${PIDS}" ]; then
      JOBS=$(jobs -p)
    else
      JOBS=$PIDS
    fi
    # wait until jobs are done 
    for pid in $JOBS; do
        if (( $(ps $pid | wc -l) > 1 )); then
          # echo "still running $JOBS"
          JOBS_CNT=$(( JOBS_CNT + 1 )) 
        fi
    done

    if (( JOBS_CNT > 0 )); then
      if (( TIMER > 0 )) && (( waited_sec > TIMER )); then
        # echo killing $PID
        kill_jobs $PIDS
      fi
    else
        break
    fi
    sleep 1
    waited_sec=$(( waited_sec + 1 ))
  done  
}

# local jdbc_url="jdbc:mariadb://${HOST}/${USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
# local jdbc_driver=${jdbc_driver:-org.mariadb.jdbc.Driver}

jdbc_shell() {
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  # does not work with MySQL
  local HOST="${1-${SRCDB_HOST}}"  
  local USER="${2:-${SRCDB_ARC_USER}}"
  local PW="${3:-${SRCDB_ARC_PW}}"
  local port="${4:-${SRCDB_PORT}}"
  local jdbc_url="${5:-${SRCDB_JDBC_URL}}"
  local jsqsh_driver="${6:-${SRCDB_JSQSH_DRIVER}}"

  ${JSQSH_DIR}/*/bin/jsqsh --driver="${jsqsh_driver}" --user="${USER}" --password="${PW}" --server="${HOST}" --port="${port}" --database="${USER}"
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
