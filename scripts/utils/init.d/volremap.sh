#!/usr/bin/env bash

mkdir -p /opt/stage/oraxe   # oracle xe redo logs
mkdir -p /opt/stage/oraee   # oracle ee redo logs
mkdir -p /opt/stage/libs    # data exchange with host docker of loadgen YAML 

# change external_uid to internal uid that can be used
map_uid() {
    local external_mnt=$1
    local internal_mnt=$2
    local external_uid=$( stat -c '%u' ${external_mnt} )

    echo $external_mnt uid=$external_uid map to $internal_mnt uid=arcion

    if [ -d "$external_mnt" ]; then 
        sudo bindfs --force-user=arcion --force-group=arcion \
        --create-for-user=${external_uid} --create-for-group=${external_uid} \
        --chown-ignore --chgrp-ignore \
        $external_mnt $internal_mnt
    fi
}

map_uid /opt/mnt/oraxe2130/oradata  /opt/stage/oraxe
map_uid /opt/mnt/oraee1930/oradata  /opt/stage/oraee
map_uid /opt/mnt/libs               /libs
map_uid /opt/mnt/loadgen            /arcion/data
