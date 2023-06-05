#!/usr/bin/env bash




arcion_version() {
   echo "me"
}

# top level parsing
# https://tldp.org/LDP/abs/html/x17129.html
#                              N
#                   *     ?    O    +
#                   0-n   0-1  T    1-n
#                      //              :           @             :             /           ?          #
error_code_pattern='^((.*)(error code:[ ]*)([0-9]+))$'
#         12   3                4
#   

# file without the dir prefix
ROOT_DIR=/opt/stage/data
for f in $(cd $ROOT_DIR; find . -name arcion.log -printf '%h\n'); do
   # for a long log, stop on first exit
   error_code=$( grep -m 1 -e 'error code: [1-9]$' $ROOT_DIR/$f/arcion.log )
   if [ -n "${error_code}" ]; then 
      continue
      echo "${f:2}: $error_code" >&2
   fi


   # Elapsed time from the end of the file
   elapsed_time=$(tac $ROOT_DIR/$f/arcion.log | awk -F'[: ]' '/Elapsed time/ {print $4 ":" $5 ":" $6 ; exit}')

   # version from the tracelog
   # skip the first 2 char of the string
   # the first should have the 
   readarray -d '-' -t run_id_array <<< "${f:2}"
   # script error where trace.log was not saved correctly
   if [ -f "$ROOT_DIR/${run_id_array[0]}/trace.log" ]; then
      arcion_version=$(awk 'NR == 5 {print $NF; exit}' $ROOT_DIR/${run_id_array[0]}/trace.log)
   else
      arcion_version="?"
   fi

   # normalize to run_id arcion_version source target replication_mode size_factor
   if [[ ${#run_id_array[@]} == 5 ]]; then
      echo "${f:2} ${elapsed_time} ${run_id_array[0]} ${arcion_version} ${run_id_array[@]:1}"
   else
      echo "${f:2} ${elapsed_time} ${run_id_array[@]}"
   fi
done