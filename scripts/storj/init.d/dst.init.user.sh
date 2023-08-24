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
alias_name=storj

# create bucket if does not exists
set -x
# create arcdst user alias
mc alias set $alias_name ${STORJ_DST_ENDPOINT} ${STORJ_DST_ID} ${STORJ_DST_SECRET}
# see if bucket exists (must be lower case)
dst_bucket=$(mc ls $alias_name/${STORJ_DST_DB,,} | awk '{print $NF}')
# create bucket if does not exist
if [ -z "${dst_bucket}" ]; then
    mc mb  --with-lock $alias_name/${STORJ_DST_DB}
fi
# list buckets 
mc ls -r $alias_name/${STORJ_DST_DB}
set +x
