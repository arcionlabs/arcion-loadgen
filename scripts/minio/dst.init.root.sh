#!/usr/bin/env bash

# root connection to minio
mc alias set minio http://minio:9000 ${DSTDB_ROOT}  ${DSTDB_PW}

# add arcdst user w/ read write
mc admin user add minio ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}
mc admin policy attach minio readwrite --user ${DSTDB_ARC_USER} 
