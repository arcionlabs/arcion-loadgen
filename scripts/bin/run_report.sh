#!/usr/bin/env bash

for f in $(find /opt/stage/data -name arcion.log); do
 exit_msg=$(tail -n 1 $f)

 if [ ! -z "${exit_msg}" ]; then
    echo "$f ${exit_msg}"
 fi
done