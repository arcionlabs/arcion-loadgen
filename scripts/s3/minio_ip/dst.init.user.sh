#!/usr/bin/env bash

# alias name is the dir name of this script
PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
if [ "${PROG_DIR}" = "." ]; then
    PROG_DIR=$(basename $(pwd))
fi
if [ -n "$PROG_DIR" ]; then
    alias_name=$PROG_DIR
else
    echo "Error: the script should be in a directory to infer alias name"
fi
alias_name=minio_ip

set -x

# create arcdst user alias
mc alias set $alias_name http://${DSTDB_HOST}:${DSTDB_PORT} ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}

# create bucket if does not exists
mc mb  --with-lock $alias_name/${DSTDB_DB}

# list buckets 
mc ls -r $alias_name/${DSTDB_DB}
set +x