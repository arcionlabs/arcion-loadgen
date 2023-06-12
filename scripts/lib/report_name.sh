#!/usr/bin/env bash

# run the report from cfg dir
# return name time id 
# 
# 
report_name() {
    f=${1:-$(basename $(pwd))} 
    ROOT_DIR=${2:-$(dirname $(pwd))}

    if [ ! -f $ROOT_DIR/$f/arcion.log ]; then
        echo "${f}: $ROOT_DIR/$f/arcion.log not found. skipping" >&2
        retrn 0
    fi

    # for a long log, stop on first exit
    error_code=$( grep -m 1 -e 'error code: [1-9]$' $ROOT_DIR/$f/arcion.log )
    if [ -n "${error_code}" ]; then 
        echo "${f}: error code: $error_code. skipping" >&2
        return 0
    fi

   # Elapsed time from the end of the file
   elapsed_time=$(tac $ROOT_DIR/$f/arcion.log | awk -F'[: ]' '/Elapsed time/ {print $4 ":" $5 ":" $6 ; exit}')
   if [ -z "$elapsed_time" ]; then
        echo "${f}: no elapsed time skipping" >&2
        return 0
   fi

   # 3ed3da197-23.04.30.16-postgresql_v1503_1-mysql_v8033_2-full-1
   # 0 runid   1 arcion version               |             |    |
   #                       |                  |             |    |
   #                       2 source db        3 dest db     4 repl mode
   #                                                             5 size factor

   # version from the tracelog
   readarray -d '-' -t run_id_array <<< "${f}"

   # parse invidiual element
   run_id=${run_id_array[0]}
   run_repl_mode=${run_id_array[4]}

   readarray -d '_' -t run_src <<< ${run_id_array[2]}
   readarray -d '_' -t run_dst <<< ${run_id_array[3]}
   if [ -z "${run_src[1]}" ]; then
      run_src[1]="latest"
      run_src[2]="src"
   fi

   if [ -z "${run_dst[1]}" ]; then
      run_dst[1]="latest"
      run_dst[2]="dst"
   fi

   run_id_array[2]=$(echo ${run_src[*]})
   run_id_array[3]=$(echo ${run_dst[*]})

   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' $ROOT_DIR/${run_id}/trace.log)
   else
        echo "${f}: no trace.log skipping" >&2
        return 0
   fi

   # number of lines from error_trace.log
   if [ -f "$ROOT_DIR/${run_id}/error_trace.log" ]; then
      error_trace_log_cnt=$(grep 'ERROR' $ROOT_DIR/${run_id}/error_trace.log | wc -l)
   else
      error_trace_log_cnt=0
   fi   

   # snapshot summary that has the following
   # table_cnt " " total_row_cnt
   if [ -f "$ROOT_DIR/${run_id}/snapshot_summary.txt" ]; then
      snapshot_total_rows=$(cat $ROOT_DIR/${run_id}/snapshot_summary.txt | \
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
      tac $ROOT_DIR/$f/arcion.log | \
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

   # normalize to run_id arcion_version source target replication_mode size_factor
   if [[ ${#run_id_array[@]} == 5 ]]; then
      echo "${f} ${elapsed_time} ${error_trace_log_cnt} ${snapshot_total_rows} ${realtime_total_rows} ${delta_total_rows} ${run_id_array[0]} ${arcion_version} ${run_id_array[@]:1}" | tr '-' '_'
   else
      echo "${f} ${elapsed_time} ${error_trace_log_cnt} ${snapshot_total_rows} ${realtime_total_rows} ${delta_total_rows} ${run_id_array[@]}" | tr '-' '_'
   fi
}