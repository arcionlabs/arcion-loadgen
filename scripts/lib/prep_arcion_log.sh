#!/usr/bin/env bash

prep_arcion_log() {
    
# arcion data (log dir)
if [ -z "$ARCION_LOG" ]; then
  export ARCION_LOG=/opt/stage/loadgen
fi

# typically log dir should already exist
if [ -d "${ARCION_LOG}" ]; then
  echo "Testing ${ARCION_LOG} for create dir priv" 
  test_dir=$(mktemp -d ${ARCION_LOG}/XXXXXXXXX)
  if [ -z "${test_dir}" ]; then
    echo "test create dir $test_dir failed." >&2
    exit 1
  else
    echo "test create dir succeeded. deleting temp dir $test_dir"
    rmdir "${test_dir}"
  fi
else
  echo "ARCION_LOG=$ARCION_LOG dir does not exist" >&2
  exit 1
fi

}