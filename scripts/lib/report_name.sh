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

   # version from the tracelog
   # skip the first 2 char of the string
   # the first should have the 
   readarray -d '-' -t run_id_array <<< "${f}"
   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id_array[0]}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' $ROOT_DIR/${run_id_array[0]}/trace.log)
   else
        echo "${f}: no trace.log skipping" >&2
        return 0
   fi

   # normalize to run_id arcion_version source target replication_mode size_factor
   if [[ ${#run_id_array[@]} == 5 ]]; then
      echo "${f} ${elapsed_time} ${run_id_array[0]} ${arcion_version} ${run_id_array[@]:1}" | tr '-' '_'
   else
      echo "${f} ${elapsed_time} ${run_id_array[@]}" | tr '-' '_'
   fi
}