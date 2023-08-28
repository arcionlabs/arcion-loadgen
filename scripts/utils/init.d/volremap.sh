#!/usr/bin/env bash

mkdir -p /opt/stage/libs    # data exchange with host docker of loadgen YAML 
mkdir -p /opt/stage/data    # data exchange with host docker of loadgen YAML 

# change external_uid to internal uid that can be used
map_uid() {
    local external_mnt=$1
    local internal_mnt=$2
    local opts="$3"
    local external_uid=$( stat -c '%u' ${external_mnt} )

    mkdir -p $internal_mnt

    echo $external_mnt uid=$external_uid map to $internal_mnt uid=arcion $opts

    if [ -d "$external_mnt" ]; then 
        sudo bindfs --force-user=arcion --force-group=arcion \
        --create-for-user=${external_uid} --create-for-group=${external_uid} \
        --chown-ignore --chgrp-ignore --chmod-ignore ${opts} \
        $external_mnt $internal_mnt
    fi
}

# map source target
map_uid /opt/mnt/libs       /opt/stage/libs '-o nonempty'
map_uid /opt/mnt/loadgen    /opt/stage/data '-o nonempty'

# oracle dirs
for d in $(find /opt/mnt -maxdepth 1 -type d -name "ora*"); do 
    oradir=$(basename ${d})
    if [ -d "${d}/oradata" ]; then 
        echo map_uid ${d}/oradata  /opt/stage/${oradir}
        map_uid ${d}/oradata  /opt/stage/${oradir}
    fi
done

# oracle share dir (make sure the name match oracle)
map_uid /opt/mnt/orashared    /opt/oracle/share
