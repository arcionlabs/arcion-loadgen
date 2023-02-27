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

  ${JSQSH_DIR}/*/bin/jsqsh --driver="${jsqsh_driver}" --user="${USER}" --password="${PW}" --server="${HOST}" --port="${port}" --database="${USER}" 2>&1
}

ycsb_truncate() {
  echo "truncate usertable;" | jdbc_shell
}

ycsb_rows() {
  echo "select max(ycsb_key) from usertable;" | jdbc_shell | grep "^| user" | sed 's/user//' | awk '{print int($2)}'
}

ycsb_load_sf() {
  local ycsb_insertstart=0
  local ycsb_recordcount=1000000

  local OPTIND options
  while getopts ":s:" options; do
    case "${options}" in
      s)
        ycsb_size_factor=${OPTARG}
        ;;
    esac
  done
  shift $((OPTIND-1))

  for i in $( seq 1 1 $ycsb_size_factor ); do 
    # skip if already done
    echo Checking user$ycsb_insertstart
    ycsb_key=$( echo "select ycsb_key from usertable where ycsb_key='user$ycsb_insertstart';" | jdbc_shell | grep "rows in result" | cut -d' ' -f1 )

    if [ "$ycsb_key" = "0" ]; then 
      echo "start insert at $ycsb_insertstart"
      ycsb_load_src $ycsb_insertstart
    fi
    ycsb_insertstart=$(( ycsb_insertstart + ycsb_recordcount ))
  done
}

ycsb_load_src() { 
# https://github.com/brianfrankcooper/YCSB/wiki/Running-a-Workload
  local ycsb_insertstart=${1:-0}
  local ycsb_recordcount=${2:-1000000}
  local HOST="${3-${SRCDB_HOST}}"  
  local USER="${4:-${SRCDB_ARC_USER}}"
  local PW="${5:-${SRCDB_ARC_PW}}"
  local port="${6:-${SRCDB_PORT}}"
  local jdbc_url="${7:-${SRCDB_JDBC_URL}}"
  local jdbc_driver="${8:-${SRCDB_JDBC_DRIVER}}"
  local THREADS=${9:-$(getconf _NPROCESSORS_ONLN)}

  jdbc_url="${jdbc_url}&rewriteBatchedStatements=true"

  ${YCSB}/*jdbc*/bin/ycsb.sh load jdbc -s -threads ${THREADS} \
    -p workload=site.ycsb.workloads.CoreWorkload \
    -p db.driver="${jdbc_driver}" \
    -p db.url="${jdbc_url}" \
    -p db.user=${USER} \
    -p db.passwd=${PW} \
    -p db.batchsize=1024  \
    -p jdbc.fetchsize=10 \
    -p jdbc.autocommit=true \
    -p jdbc.batchupdateapi=true \
    -p insertstart=$ycsb_insertstart \
    -p recordcount=${ycsb_recordcount} \
    -p requestdistribution=uniform \
    -p zeropadding=11 \
    -p insertorder=ordered
}

ycsb_run_src() {
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
  local ycsb_recordcount=${ycsb_recordcount:-${ycsb_rows_per_sf}}
  local ycsb_insertstart=${ycsb_insertstart:-0}
  local ycsb_operationcount=${ycsb_operationcount:-$((${ycsb_recordcount}*${ycsb_threads}*${ycsb_timer}))}

  ycsb_recordcount=$( ycsb_rows )
  echo $ycsb_recordcount
  if (( ycsb_recordcount == 0 )); then
    return
  fi
  ycsb_recordcount=$(( ycsb_recordcount + 1 ))

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
  -p db.batchsize=1024  \
  -p jdbc.fetchsize=10 \
  -p jdbc.autocommit=true \
  -p requestdistribution=uniform \
  -p zeropadding=11 \
  -p insertorder=ordered &    
  # save the PID  
  export YCSB_RUN_PID="$!"
  # wait 
  if (( ycsb_timer != 0 )); then
    wait_jobs "$YCSB_RUN_PID" "${ycsb_timer}"
  fi
}
