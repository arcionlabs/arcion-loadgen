#!/usr/bin/env bash

# root connection to minio
mc alias set minio http://minio:9000 root Passw0rd

# add arcdst user w/ read write
mc admin user add minio arcdst Passw0rd
mc admin policy attach minio readwrite --user arcdst
