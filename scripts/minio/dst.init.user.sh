#!/usr/bin/env bash

# create arcdst user alias
mc alias set arcdst http://minio:9000 arcdst Passw0rd
# create arcdst bucket
mc mb  --with-lock arcdst/arcdst
