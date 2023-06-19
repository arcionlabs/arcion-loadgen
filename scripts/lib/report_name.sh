#!/usr/bin/env bash

# read yaml file, look for host, split it into name version role triplet
split_host_to_triplet() {
   local FILENAME=$1
   local ROLE=$2
   local HOST
   
   HOST=$( yq -r '.host' $FILENAME )

   readarray -d '-' -t HOST_ARRAY <<< ${HOST}
   if [ -z "${HOST_ARRAY[1]}" ]; then
      HOST_ARRAY[1]="latest"
      HOST_ARRAY[2]="src"
   fi   

   if [ -z "${HOST_ARRAY[2]}" ]; then
      HOST_ARRAY[2]=${ROLE}
   fi   

   HOST_ARRAY[0]=$( echo ${HOST_ARRAY[0]} | awk -F'.' '{print $1}' )

   echo ${HOST_ARRAY[*]}
}

# read threads from extractor and applier yaml 
get_extractor_applier_threads() {
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

   run_repl_mode=$( get_replication_mode ${LOG_DIR})

   run_id_array[2]=$( split_host_to_triplet ${CFG_DIR}/src.yaml src)
   run_id_array[3]=$( split_host_to_triplet ${CFG_DIR}/dst.yaml dst)

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
   # table_cnt " " total_row_cnt
   if [ -f "${LOG_DIR}/snapshot_summary.txt" ]; then
      snapshot_total_rows=$(cat ${LOG_DIR}/snapshot_summary.txt | \
         awk '
            BEGIN {namespace=0; table_cnt=0; row_cnt=0}
            $1=="Namespace" {namespace=1;next}
            namespace==1 && NF==0 {namespace=0; next}
            namespace==1 && NF==7 {table_cnt++; row_cnt=row_cnt+$NF}
            END {print table_cnt " " row_cnt}
         ' )
   else
      snapshot_total_rows="0 0"
   fi   

   # real-time summary 
   if [ "${run_repl_mode}" != "snapshot" ]; then
      tac ${CFG_DIR}/arcion.log | \
         awk '
            {print $0}
            $1=="Table" && $2=="name" {exit}
         ' > /tmp/real_time.log.$$
   else
      touch /tmp/real_time.log.$$
   fi
   # table_cnt " " inserted " " deleted " " updated " " replaced
   realtime_total_rows=$( tac /tmp/real_time.log.$$ | \
      awk '
         BEGIN {inserted=0; deleted=0; updated=0; replaced=0; table_cnt=0; num_of_columns=0; tablename=0}
         $1=="Table" && $2=="name" {tablename=1; num_of_columns=NF-1; next}
         tablename==1 && NF==num_of_columns {inserted+=$2; deleted+=$3; updated+=$4; replaced+=$5; table_cnt++}
         END {print table_cnt " " inserted " " deleted " " updated " " replaced}
      ' )
   # applied incoming
   delta_total_rows=$( tac /tmp/real_time.log.$$ | \
      awk -F '[[:space:]/]+' '
         BEGIN {applied=0; incoming=0; table_cnt=0; replication_found=0}
         $1=="Table" && $2=="name" && $3=="Replication" {replication_found=1; next}
         replication_found==1 && NF>1 {table_cnt++; applied+=$(NF-3); incoming+=$(NF-2)}
         END {print table_cnt " " applied " " incoming}
      ' )
   # cleanup
   rm /tmp/real_time.log.$$

   if [[ "${snapshot_total_rows}" = "0 0" ]] &&  [[ "${realtime_total_rows}" = "0 0 0 0 0" ]] && [[ "${delta_total_rows}" = "0 0 0" ]]; then
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