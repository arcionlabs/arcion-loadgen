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
  # echo "kill_jobs $(jobs -p)"
  for pid in $(jobs -p); do
    # kill -2 kills parent and the child
    echo kill_recurse $pid
    kill_recurse $pid
  done
}

wait_jobs() {
  local TIMER="${1:-600}"
  local PIDS="$2"
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
    # echo "waiting for $JOBS to finish"
    for pid in $JOBS; do
        PID_CNT=$( ps $pid | wc -l )
        if [ ! -z "$PID_CNT" ] && [ "$PID_CNT" -gt 1 ]; then
          # echo "still running $JOBS"
          JOBS_CNT=$(( JOBS_CNT + 1 )) 
        fi
    done

    if (( TIMER > 0 )) && (( waited_sec > TIMER )); then
      break
    else    
      sleep 1
      waited_sec=$(( waited_sec + 1 ))
    fi
  done  
  echo "$JOBS_CNT"
}
