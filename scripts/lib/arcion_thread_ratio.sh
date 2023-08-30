#!/usr/bin/env bash 

export LOADGEN_TPS=1
export LOADGEN_THREADS=1

export SRCDB_SNAPSHOT_THREADS=1
export SRCDB_REALTIME_THREADS=1
export SRCDB_DELTA_SNAPSHOT_THREADS=1
export DSTDB_SNAPSHOT_THREADS=1
export DSTDB_REALTIME_THREADS=1

# $1 = ratio in "1:2"
# $2 = default if ratio in 0 or space
# return c1 and c2
get_tuple() {
    c1=$( echo $1 | cut -d: -f1 )
    if [ "${c1}" = "0" ] || [ -z "${c1}" ]; then c1=$2; fi
    
    c2=$( echo $1 | cut -d: -f2 )
    if [ "${c2}" = "0" ] || [ -z "${c2}" ]; then c2=$2; fi
} 

# $1=snapshot_thread_ratio
# $2=cdc_thread_ratio
parse_arcion_thread_ratio() {

    get_tuple "${snapshot_thread_ratio}" "${max_cpus}"
    export SRCDB_SNAPSHOT_THREADS=${c1}
    export DSTDB_SNAPSHOT_THREADS=${c2}

    get_tuple "${cdc_thread_ratio}" "${max_cpus}"
    export SRCDB_REALTIME_THREADS=${c1}
    export DSTDB_REALTIME_THREADS=${c2}

    export SRCDB_DELTA_SNAPSHOT_THREADS=${SRCDB_SNAPSHOT_THREADS}
}
