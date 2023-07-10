#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/arcionlog_parser.sh
. ${SCRIPTS_DIR}/lib/tracelog_yaml_extract.sh

# convert trace.log to yaml
trace_to_yaml( ) {
   #set -x
   export SRC_HOST=$(cat  ${LOG_DIR}/yaml/src.yaml | yq -r '.host')
   [[ "$SRC_HOST" = "null" ]] && SRC_HOST=$(cat ${LOG_DIR}/yaml/dst.yaml | yq -r '.endpoint."service-endpoint"' | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|\:.*$||' )

   export DST_HOST=$(cat  ${LOG_DIR}/yaml/dst.yaml | yq -r '.host')
   [[ "$DST_HOST" = "null" ]] && DST_HOST=$(cat ${LOG_DIR}/yaml/dst.yaml | yq -r '.endpoint."service-endpoint"' | sed -e 's|^[^/]*//||' -e 's|/.*$||' -e 's|\:.*$||' )

   export EXT_SNAP_THREADS=$(cat ${LOG_DIR}/yaml/ext_snap.yaml | yq -r '."threads"')
   EXT_SNAP_THREADS=${EXT_SNAP_THREADS:-0}
   export EXT_SNAP_FETCH_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/ext_snap.yaml | yq -r '."fetch-size-rows"')
   EXT_SNAP_FETCH_SIZE_ROWS=${EXT_SNAP_FETCH_SIZE_ROWS:-0}
   export EXT_SNAP_MAX_JOBS_PER_CHUNK=$(cat ${LOG_DIR}/yaml/ext_snap.yaml | yq -r '."max-jobs-per-chunk"')
   EXT_SNAP_MAX_JOBS_PER_CHUNK=${EXT_SNAP_MAX_JOBS_PER_CHUNK:-0}
   export EXT_SNAP_MIN_JOB_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/ext_snap.yaml | yq -r '."min-job-size-rows"')
   EXT_SNAP_MIN_JOB_SIZE_ROWS=${EXT_SNAP_MIN_JOB_SIZE_ROWS:-0}

   export EXT_REAL_THREADS=$(cat ${LOG_DIR}/yaml/ext_realtime.yaml | yq -r '."threads"')
   EXT_REAL_THREADS=${EXT_REAL_THREADS:-0}
   export EXT_REAL_FETCH_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/ext_realtime.yaml | yq -r '."fetch-size-rows"')
   EXT_REAL_FETCH_SIZE_ROWS=${EXT_REAL_FETCH_SIZE_ROWS:-0}

   export EXT_REAL_THREADS=0

   export APP_SNAP_THREADS=$(cat ${LOG_DIR}/yaml/app_snap.yaml | yq -r '."threads"')
   APP_SNAP_THREADS=${APP_SNAP_THREADS:-0}
   export APP_SNAP_BATCH_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/app_snap.yaml | yq -r '."batch-size-rows"')
   APP_SNAP_BATCH_SIZE_ROWS=${APP_SNAP_BATCH_SIZE_ROWS:-0}
   export APP_SNAP_TXN_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/app_snap.yaml | yq -r '."txn-size-rows"')
   APP_SNAP_TXN_SIZE_ROWS=${APP_SNAP_TXN_SIZE_ROWS:-0}
   export APP_SNAP_BULK_LOAD_TYPE=$(cat ${LOG_DIR}/yaml/app_snap.yaml | yq -r '."bulk-load".type')
   APP_SNAP_BULK_LOAD_TYPE=${APP_SNAP_BULK_LOAD_TYPE:-0}

   export APP_REAL_THREADS=$(cat ${LOG_DIR}/yaml/app_realtime.yaml | yq -r '."threads"')
   APP_REAL_THREADS=${APP_REAL_THREADS:-0}
   export APP_REAL_BATCH_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/app_realtime.yaml | yq -r '."batch-size-rows"')
   APP_REAL_BATCH_SIZE_ROWS=${APP_REAL_BATCH_SIZE_ROWS:-0}
   export APP_REAL_TXN_SIZE_ROWS=$(cat ${LOG_DIR}/yaml/app_realtime.yaml | yq -r '."txn-size-rows"')
   APP_REAL_TXN_SIZE_ROWS=${APP_REAL_TXN_SIZE_ROWS:-0}

   export APP_REAL_THREADS=0
   #set +x
}

get_extractor_applier_threads() {
   echo ${EXT_SNAP_THREADS} ${EXT_REAL_THREADS} ${EXT_REAL_THREADS} \
      ${APP_SNAP_THREADS} ${APP_REAL_THREADS} ${APP_REAL_THREADS} \
      $EXT_SNAP_FETCH_SIZE_ROWS $EXT_SNAP_MAX_JOBS_PER_CHUNK $EXT_SNAP_MIN_JOB_SIZE_ROWS $EXT_REAL_FETCH_SIZE_ROWS \
      $APP_SNAP_BATCH_SIZE_ROWS $APP_SNAP_TXN_SIZE_ROWS $APP_SNAP_BULK_LOAD_TYPE $APP_REAL_BATCH_SIZE_ROWS $APP_REAL_TXN_SIZE_ROWS
}

# read yaml file, look for host, split it into name version role triplet
split_host_to_triplet() {
   local FILENAME=$1
   local ROLE=$2
   local HOST=$3
   
   [[ -z "$HOST" ]] && HOST=$( yq -r '.host' $FILENAME )

   readarray -d '-' -t HOST_ARRAY <<< ${HOST}
   if [ -z "${HOST_ARRAY[1]}" ]; then
      HOST_ARRAY[1]="latest"
      HOST_ARRAY[2]=${ROLE}
   fi   

   if [ -z "${HOST_ARRAY[2]}" ]; then
      HOST_ARRAY[2]=${ROLE}
   fi   

   # swithc from host-src-version to host-version-src
   if [[ "${HOST_ARRAY[1],,}" = "src" ]] || [[ "${HOST_ARRAY[1],,}" = "dst" ]]; then 
      local x=${HOST_ARRAY[2]}
      HOST_ARRAY[2]=${HOST_ARRAY[1]}
      HOST_ARRAY[1]=${x}
   fi

   HOST_ARRAY[0]=$( echo ${HOST_ARRAY[0]} | awk -F'.' '{print $1}' )

   echo ${HOST_ARRAY[@]:0:3} # print first 3 elements
}

# read threads from extractor and applier yaml 
get_extractor_applier_threads_from_input() {
   local CFG_DIR=${1:-$(pwd)}
   local EXTRACTOR_SNAPSHOT_THREADS=0
   local EXTRACTOR_REALTIME_THREADS=0
   local EXTRACTOR_DELTA_THREADS=0
   local APPLIER_SNAPSHOT_THREADS=0
   local APPLIER_REALTIME_THREADS=0
   local APPLIER_DELTA_THREADS=0

   x=$( yq -r '.snapshot.threads' $CFG_DIR/src_extractor.yaml 2>/dev/null )
   [[ $x ]] && EXTRACTOR_SNAPSHOT_THREADS=${x}
   x=$( yq -r '.realtime.threads' $CFG_DIR/src_extractor.yaml 2>/dev/null)
   [[ $x ]] && EXTRACTOR_REALTIME_THREADS=${x}
   x=$( yq -r '."delta-snapshot".threads' $CFG_DIR/src_extractor.yaml 2>/dev/null)
   [[ $x ]] && EXTRACTOR_DELTA_THREADS=${x}

   x=$( yq -r '.snapshot.threads' $CFG_DIR/dst_applier.yaml 2>/dev/null)
   [[ $x ]] && APPLIER_SNAPSHOT_THREADS=${x}
   x=$( yq -r '.realtime.threads' $CFG_DIR/dst_applier.yaml 2>/dev/null)
   [[ $x ]] && APPLIER_REALTIME_THREADS=${x}
   x=$( yq -r '."delta-snapshot".threads' $CFG_DIR/dst_applier.yaml 2>/dev/null)
   [[ $x ]] && APPLIER_DELTA_THREADS=${x}

   echo ${EXTRACTOR_SNAPSHOT_THREADS} ${EXTRACTOR_REALTIME_THREADS} ${EXTRACTOR_DELTA_THREADS} \
      ${APPLIER_SNAPSHOT_THREADS} ${APPLIER_REALTIME_THREADS} ${APPLIER_DELTA_THREADS} 
}


get_replication_mode() {
   local LOG_DIR=${1:-$(pwd)}
   local REPL_MODE

   REPL_MODE=$(head -n 10 ${LOG_DIR}/trace.log | grep 'Command :' | sed s'/^.*Command : \(.*\)$/\1/' | awk '{print $2}')

   if [ -z "${REPL_MODE}" ]; then
      REPL_MODE=$(head -n 10 ${LOG_DIR}/error_trace.log | grep 'Command :' | sed s'/^.*Command : \(.*\)$/\1/' | awk '{print $2}')
   fi

   if [ -z "${REPL_MODE}" ]; then
      REPL_MODE="unknown"
   fi

   echo $REPL_MODE
}

# run the report from cfg dir
# dirname convention 
# 3ed3da197-23.04.30.16-postgresql_v1503_1-mysql_v8033_2-full-1
# 0 runid   1 arcion version               |             |    |
#                       |                  |             |    |
#                       2 source db        3 dest db     4 repl mode
#                                                             5 size factor
report_name() {
   local f=${1:-$(basename $(pwd))} 
   local ROOT_DIR=${2:-$(dirname $(pwd))}
   local CFG_DIR=${ROOT_DIR}/${f}

   readarray -d '-' -t run_id_array < <(printf '%s' "$f") # does not have new line at the end
   local run_id=${run_id_array[0]}
   local LOG_DIR=${ROOT_DIR}/${run_id}

    if [ ! -f ${CFG_DIR}/arcion.log ]; then
        echo "${f}: ${CFG_DIR}/arcion.log not found. skipping" >&2
        return 0
    fi

    # for a long log, stop on first exit
    error_code=$( grep -m 1 -e 'error code: [1-9]$' ${CFG_DIR}/arcion.log )
    if [ -n "${error_code}" ]; then 
        echo "${f}: error code: $error_code. skipping" >&2
        return 0
    fi

   # Elapsed time from the end of the file
   elapsed_time=$(tac ${CFG_DIR}/arcion.log | awk -F'[: ]' '/Elapsed time/ {print $4 ":" $5 ":" $6 ; exit}')
   if [ -z "$elapsed_time" ]; then
        echo "${f}: no elapsed time skipping" >&2
        return 0
   fi

    if [ ! -f ${LOG_DIR}/trace.log ]; then
        echo "${f}: ${LOG_DIR}/trace.log not found. skipping" >&2
        return 0
    fi
   tracelog_save_as_yaml ${LOG_DIR}
   trace_to_yaml

   run_repl_mode=$( get_replication_mode ${LOG_DIR})

   run_id_array[2]=$( split_host_to_triplet ${CFG_DIR}/src.yaml src "${SRC_HOST}")
   run_id_array[3]=$( split_host_to_triplet ${CFG_DIR}/dst.yaml dst "${DST_HOST}")

   # script error where trace.log was not saved correctly
   if [ -f "${LOG_DIR}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' ${LOG_DIR}/trace.log)
   else
        echo "${f}: no trace.log skipping" >&2
        return 0
   fi

   # number of lines from error_trace.log
   if [ -f "${LOG_DIR}/error_trace.log" ]; then
      error_trace_log_cnt=$(grep 'ERROR' ${LOG_DIR}/error_trace.log | wc -l)
   else
      error_trace_log_cnt=0
   fi   

   # snapshot summary that has the following
   arcionlog_snap_parser

   # real-time summary 
   arcionlog_real_delta_parser

   if [[ "${snapshot_total_rows}" = "$SNAPSHOT_TOTAL_ROWS_NULL" ]] &&  [[ "${realtime_total_rows}" = "0 0 0 0 0" ]] && [[ "${delta_total_rows}" = "0 0 0" ]]; then
      echo "${f}: no rows were processed. skipping" >&2
      return 0
   fi

   # normalize to run_id arcion_version source target replication_mode size_factor ext_snap_threads ext_real_threads ext_delta_threads app_snap_threads app_real_threads app_delta_threads
   if [[ ${#run_id_array[@]} == 5 ]]; then
      echo "${f} ${elapsed_time} ${error_trace_log_cnt} ${snapshot_total_rows} ${realtime_total_rows} ${delta_total_rows} ${run_id_array[0]} ${arcion_version} ${run_id_array[@]:1} $(get_extractor_applier_threads $CFG_DIR)" | tr '-' '_'
   else
      echo "${f} ${elapsed_time} ${error_trace_log_cnt} ${snapshot_total_rows} ${realtime_total_rows} ${delta_total_rows} ${run_id_array[@]} $(get_extractor_applier_threads $CFG_DIR)" | tr '-' '_'
   fi
}