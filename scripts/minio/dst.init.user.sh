#!/usr/bin/env bash

# create arcdst user alias
mc alias set ${DSTDB_ARC_USER} http://minio:9000 ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}
# create arcdst bucket
mc mb  --with-lock ${DSTDB_ARC_USER}/${DSTDB_DB}
# list buckets 
mc ls -r ${DSTDB_ARC_USER}/${DSTDB_DB}
# Creating an object whose name ends with a "/" will create a folder. It is an empty object that simulates a directory. link

