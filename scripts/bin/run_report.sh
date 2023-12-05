#!/usr/bin/env bash

[ -z "$SCRIPTS_DIR" ] && { echo "export SCIRPTS_DIR missing." >&2; exit 1; }

. ${SCRIPTS_DIR}/lib/report_name.sh

# file without the dir prefix
if [ -z "$ROOT_DIR" ]; then
   if [ -d /opt/stage/loadgen ]; then 
      ROOT_DIR=/opt/stage/loadgen
   else
      ROOT_DIR=$(pwd)
   fi
fi

# report on dir that has `arcion.log` file
# find * don't show dirname and ./
# %h=dirname
for f in $(cd $ROOT_DIR; find * -name arcion.log -printf '%h\n'); do

   # skip already processed dir
   if [ -f ${ROOT_DIR}/$f/arcion.success.csv ]; then
      echo "$f: marked as successful run. skipping" >&2
      continue
   elif [ -f ${ROOT_DIR}/$f/arcion.fail.csv ]; then
      echo "$f: marked as failed. skipping" >&2
      continue
   fi

   # process
   echo $f >&2
   ARCION_RUN_SUCCESS_STAT=$(report_name ${f} ${ROOT_DIR})

   # save run stat
   if [ -n "$ARCION_RUN_SUCCESS_STAT" ]; then 
      echo $ARCION_RUN_SUCCESS_STAT > ${ROOT_DIR}/$f/arcion.success.csv
   else
      touch ${ROOT_DIR}/$f/arcion.fail.csv
   fi
done