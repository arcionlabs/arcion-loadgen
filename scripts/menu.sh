#!/usr/bin/env bash

ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

JOB_HOME=${JOB_HOME:-/jobs}

# env vars that can be set to skip questions
# YAML_DIR
# SRCDB_TYPE
# DSTDB_TYPE
# REPL_TYPE

# subsutite env var in YAML with the actual
copy_yaml() {
    local SRCDB_TYPE=$1
    local DSTDB_TYPE=$2
    local JOB="$1/$2"
    export YAML_DIR=/tmp/$JOB.$$
    mkdir -p $YAML_DIR
    for f in $JOB_HOME/$SRCDB_TYPE/src*.yaml; do 
        echo envsubst $f
        cat $f | envsubst > $YAML_DIR/$(basename $f) 
    done
    for f in $JOB_HOME/$DSTDB_TYPE/dst*.yaml; do 
        echo envsubst $f
        cat $f | envsubst > $YAML_DIR/$(basename $f) 
    done
}
# return command parm given source and target pair
arcion_param() {
    local src_dir=${1:-.}
    local dst_dir=${2:-$src_dir}

    src=$(find ${src_dir} -maxdepth 1 -name src.yaml -print)
    filter=$(find ${src_dir} -maxdepth 1 -name src_filter.yaml -print)
    extractor=$(find ${src_dir} -maxdepth 1 -name src_extractor.yaml -print)

    dst=$(find ${dst_dir} -maxdepth 1 -name dst.yaml -print)
    applier=$(find ${dst_dir} -maxdepth 1 -name dst_applier.yaml -print)

    echo ${src} ${dst} ${filter+'--filter' $filter} ${extractor+'--extractor' $extractor} ${applier+'--applier' $applier}
}
arcion_delta() {
    export LOG=${1:-delta}.$$
    pushd $ARCION_HOME
    ./bin/replicant delta-snapshot \
    $( arcion_param ${YAML_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG | tee delta.log
    popd
}
arcion_real() {
    export LOG=${1:-real}.$$
    pushd $ARCION_HOME
    ./bin/replicant real-time \
    $( arcion_param ${YAML_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG | tee real.log
    popd
}
arcion_full() {
    export LOG=${1:-full}.$$
    pushd $ARCION_HOME
    ./bin/replicant full \
    $( arcion_param ${YAML_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG | tee full.log
    popd
}
arcion_snapshot() {
    export LOG=${1:-snap}.$$
    pushd $ARCION_HOME
    ./bin/replicant snapshot \
    $( arcion_param ${YAML_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG | tee snap.log
    popd
}
# find source DB dir that has src.yaml, filter.yaml and extractor.yarm
find_srcdb() {
    find * -type f \( -iname "src.yaml" -o -iname "src_filter*.yaml" -o -iname "src_extractor.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do if (( count == 3 )); then echo $dir; fi; done 
}
# find dst DB dir that has dst.yaml, applier.yaml 
find_dstdb() {
    find * -type f \( -iname "dst.yaml" -o -iname "dst_applier.yaml" \) -print | \
    xargs dirname | \
    uniq -c | \
    while read count dir; do if (( count == 2 )); then echo $dir; fi; done
}
find_hosts() {
    if [ ! -f /tmp/names.$$.txt ]; then
        ip=$( hostname -i | awk -F'.' '{print $1"."$2"."$3"."0"/24"}' )
        nmap -sn -oG /tmp/names.$$.txt $ip >/dev/null
    fi
    cat /tmp/names.$$.txt | grep 'arcnet' | awk -F'[ ()]' '{print $4}'
}
ask_src_host() {
    PS3='Please enter the SOURCE host: '
    options=( $(find_hosts) )
    select SRCDB_HOST in "${options[@]}"; do
        if [ ! -z "$SRCDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_HOST
}
ask_dst_host() {
    PS3='Please enter the DESTINATION host: '
    options=( $(find_hosts) )
    select DSTDB_HOST in "${options[@]}"; do
        if [ ! -z "$DSTDB_HOST" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_HOST
}
ask_src_type() {
    PS3='Please enter the source: '
    options=( $(find_srcdb) )
    select SRCDB_TYPE in "${options[@]}"; do
        if [ -d "$SRCDB_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_TYPE
}
ask_dst_type() {
    PS3='Please enter the target: '
    options=( $(find_dstdb) )
    select DSTDB_TYPE in "${options[@]}"; do
        if [ -d "$DSTDB_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_TYPE
}
ask_repl_mode() {
    PS3='Please enter the replication type: '
    options=( "full" "snapshot" "delta-snapshot" "real-time" )
    select REPL_TYPE in "${options[@]}"; do
        if [ ! -z "$REPL_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export REPL_TYPE
}

if [ -z "${SRCDB_HOST}" ]; then ask_src_host; fi
if [ -z "${DSTDB_HOST}" ]; then ask_dst_host; fi

# set config file
if [ -z "$YAML_DIR" -o ! -d "$YAML_DIR" ]; then
    # set source and destination
    if [ -z "${SRCDB_TYPE}" -o ! -d "${SRCDB_TYPE}" ]; then ask_src_type; fi
    if [ -z "${DSTDB_TYPE}" -o ! -d "${DSTDB_TYPE}"  ]; then ask_dst_type; fi
    echo ${SRCDB_TYPE} ${DSTDB_TYPE}

    copy_yaml ${SRCDB_TYPE} ${DSTDB_TYPE}
fi
echo ${YAML_DIR}

# set replication type
if [ -z "${REPL_TYPE}" ]; then ask_repl_mode; fi
echo ${REPL_TYPE}

# run the replication
case ${REPL_TYPE} in
  full)
    arcion_full
    echo $LOG
    ;;
  snapshot)
    arcion_snapshot
    echo $LOG
    ;;
  delta-snapshot)
    arcion_delta
    echo $LOG
    ;;
  real-time)
    arcion_real
    echo $LOG
    ;;    
  *)
    echo "REPL_TYPE: ${REPL_TYPE} unsupported"
    ;;
esac
echo "log is at $ARCION_HOME/data/$LOG"
