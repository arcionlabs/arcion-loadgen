#!/usr/bin/env bash

. ${SCRIPTS_DIR}/lib/report_name.sh

# file without the dir prefix
ROOT_DIR=/opt/stage/data
for f in $(cd $ROOT_DIR; find . -name arcion.log -printf '%h\n'); do
   # skip ./ in the name
   echo $f >&2
   report_name ${f:2} ${ROOT_DIR}
done