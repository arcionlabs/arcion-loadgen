#!/usr/bin/env bash

kill_recurse() {
    cpids=`pgrep -P $1|xargs`
    for cpid in $cpids;
    do
        kill_recurse $cpid
    done
    kill -9 $1 2>/dev/null
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
  local TIMER="${2:-600}"
  local TRAP_CTL_C=${3}
  local JOBS_CNT=1
  local waited_sec=0

  # allow ctl-c to kill background jobs
  if [ ! -z "$TRAP_CTL_C" ]; then trap kill_jobs SIGINT; fi

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
