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
  local PIDS=$1
  local JOBS=$1

  if [ -z "${PIDS}" ]; then
    JOBS=$(jobs -p)
  else
    JOBS=$PIDS
  fi

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
          echo "still running $JOBS"
          JOBS_CNT=$(( JOBS_CNT + 1 )) 
        fi
    done

    if (( JOBS_CNT > 0 )); then
      if (( TIMER > 0 )) && (( waited_sec > TIMER )); then
        echo killing $PID
        kill_jobs $PIDS
      fi
    else
        break
    fi
    sleep 1
    waited_sec=$(( waited_sec + 1 ))
  done  
}

ycsb_shell() {
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local HOST="${1:-mysql}"  
  local USER="${2:-arcsrc}"
  local PW="${4:-password}"
  local jdbc_url="jdbc:mariadb://${HOST}/${USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
  local jdbc_driver=${jdbc_driver:-org.mariadb.jdbc.Driver}

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
  local HOST="${1:-mysql}"  
  local USER="${2:-arcsrc}"
  local PW="${4:-password}"
  local jdbc_url="jdbc:mariadb://${HOST}/${USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
  local jdbc_driver=${jdbc_driver:-org.mariadb.jdbc.Driver}

  java -cp $(ls lib/jdbc-binding-*.jar):$CLASSPATH site.ycsb.db.JdbcDBCreateTable \
  -p db.driver="${jdbc_driver}" \
  -p db.url="${jdbc_url}" \
  -p db.user=${USER} \
  -p db.passwd=${PW} \
  -n usertable
}

ycsb_load() { 
  # https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local HOST="${1:-mysql}"  
  local USER="${2:-arcsrc}"
  local PW="${3:-password}"
  local THREADS=${THREADS:-$(getconf _NPROCESSORS_ONLN)}}
  local jdbc_url="jdbc:mariadb://${HOST}/${USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
  local jdbc_driver=${jdbc_driver:-org.mariadb.jdbc.Driver}
  local ycsb_recordcount=${ycsb_recordcount:-10000}

  jdbc_url=${jdbc_url}&rewriteBatchedStatements=true

  bin/ycsb.sh load jdbc -s -threads ${THREADS} \
  -P workloads/workloada \
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
  local HOST="${1:-mysql}"  
  local USER="${2:-arcsrc}"
  local PW="${3:-password}"
  local jdbc_url="jdbc:mariadb://${HOST}/${USER}?permitMysqlScheme&restrictedAuth=mysql_native_password"
  local jdbc_driver=${jdbc_driver:-org.mariadb.jdbc.Driver}
  local ycsb_threads=${ycsb_threads:-1}
  local ycsb_rate=${ycsb_rate:-1}
  local ycsb_timer=${ycsb_timer:-30}
  local ycsb_recordcount=${ycsb_recordcount:-10000}
  local ycsb_insertstart=${ycsb_insertstart:-0}
  local ycsb_operationcount=${ycsb_operationcount:-$((${ycsb_recordcount}*${ycsb_threads}*${ycsb_timer}))}

  bin/ycsb.sh run jdbc -s -threads ${ycsb_threads} -target ${ycsb_rate} \
  -P workloads/workloada \
  -p requestdistribution=uniform \
  -p readproportion=0 \
  -p recordcount=${ycsb_recordcount} \
  -p insertstart=${ycsb_insertstart} \
  -p operationcount=${ycsb_operationcount} \
  -p db.driver=${jdbc_driver} \
  -p db.url="${URL}" \
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

# get the setting from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi

# inputs
[ ! -z "${1}" ] && LOADGEN_TPS=$1
[ ! -z "${2}" ] && LOADGEN_THREADS=$2
[ ! -z "${3}" ] && TIMER=$3
[ -z "${TIMER}" ] && TIMER=600

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

# start the YCSB

case "${SRCDB_GRP,,}" in
  mysql|postgresql)
    pushd ${YCSB}/*jdbc*/  
    bin/ycsb.sh run jdbc -s -threads ${LOADGEN_THREADS} -target ${LOADGEN_TPS} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((1000000*$LOADGEN_THREADS)) \
    -p db.driver=${SRCDB_JDBC_DRIVER} \
    -p db.url="${SRCDB_JDBC_URL}" \
    -p db.user=${SRCDB_ARC_USER} \
    -p db.passwd="${SRCDB_ARC_PW}" \
    -p db.batchsize=1000  \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=true \
    -p db.batchsize=1000
    popd  
;;
  mongodb)
    pushd ${YCSB}/*mongodb*/  
    bin/ycsb.sh load mongodb -s -threads ${LOADGEN_THREADS} -target ${LOADGEN_TPS} \
    -P workloads/workloada \
    -p requestdistribution=uniform \
    -p readproportion=0 \
    -p recordcount=10000 \
    -p operationcount=$((1000000*$LOADGEN_THREADS)) \
    -p mongodb.url="${SRCDB_JDBC_URL}"
    popd  
    ;; 
  *)
    echo "$0: SRCDB_GRP: ${SRCDB_GRP} need to code support"
    ;;
esac 
