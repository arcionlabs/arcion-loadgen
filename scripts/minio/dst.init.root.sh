#!/usr/bin/env bash

# root connection to minio
mc alias set minio_path_root http://${DSTDB_HOST}:${DSTDB_PORT} ${DSTDB_ROOT}  ${DSTDB_PW}

# add arcdst user w/ read write
mc admin user add minio_path_root ${DSTDB_ARC_USER} ${DSTDB_ARC_PW}
mc admin policy attach minio_path_root readwrite --user ${DSTDB_ARC_USER} 
