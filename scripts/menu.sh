#!/usr/bin/env bash

ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

# env vars that can be set to skip questions
# unset DSTDB_TYPE DSTDB_HOST
# LOG_DIR
# SRCDB_HOST
# DSTDB_HOST
# SRCDB_TYPE
# DSTDB_TYPE
# REPL_TYPE

# subsutite env var in YAML with the actual
copy_yaml() {
    local SRCDB_TYPE=$1
    local DSTDB_TYPE=$2
    mkdir -p $LOG_DIR
    for f in $SCRIPTS_DIR/$SRCDB_TYPE/src*.yaml; do 
        cat $f | envsubst > $LOG_DIR/$(basename $f) 
    done
    for f in $SCRIPTS_DIR/$DSTDB_TYPE/dst*.yaml; do 
        cat $f | envsubst > $LOG_DIR/$(basename $f) 
    done
    echo "Config at $LOG_DIR"
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
    pushd $ARCION_HOME
    ./bin/replicant delta-snapshot \
    $( arcion_param ${LOG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee delta.log
    popd
}
arcion_real() {
    pushd $ARCION_HOME
    ./bin/replicant real-time \
    $( arcion_param ${LOG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee real.log
    popd
}
arcion_full() {
    pushd $ARCION_HOME
    ./bin/replicant full \
    $( arcion_param ${LOG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee full.log
    popd
}
arcion_snapshot() {
    pushd $ARCION_HOME
    ./bin/replicant snapshot \
    $( arcion_param ${LOG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee snap.log
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
    mkdir -p /tmp/arcion/nmap
    if [ ! -f /tmp/arcion/nmap/names.$$.txt ]; then
        ip=$( hostname -i | awk -F'.' '{print $1"."$2"."$3"."0"/24"}' )
        nmap -sn -oG /tmp/arcion/nmap/names.$$.txt $ip >/dev/null
    fi
    cat /tmp/arcion/nmap/names.$$.txt | grep 'arcnet' | awk -F'[ ()]' '{print $4}'
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
    options=( "snapshot" "full" "real-time" "delta-snapshot" )
    select REPL_TYPE in "${options[@]}"; do
        if [ ! -z "$REPL_TYPE" ]; then break; else echo "invalid option"; fi
    done
    export REPL_TYPE
}
init_src() {
    mkdir -p /tmp/arcion/$SRCDB_HOST
    if [ -f "${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh" ]; then
        #if [ ! -f "/tmp/arcion/$SRCDB_HOST/src.init.log" ]; then
            ( exec ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh | tee /tmp/arcion/$SRCDB_HOST/src.init.log )
        #else
        #    echo "/tmp/arcion/$SRCDB_HOST/src.init.log: skipping init"
        #fi
    else
        echo "${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh: not found"    
    fi
}
init_dst() {
    mkdir -p /tmp/arcion/$DSTDB_HOST
    if [ -f "${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sh" ]; then
        #if [ ! -f "/tmp/arcion/$DSTDB_HOST/dst.init.log" ]; then
            ( exec ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sh | tee /tmp/arcion/$DSTDB_HOST/dst.init.log )
        #else
        #    echo "/tmp/arcion/$DSTDB_HOST/dst.init.log: skipping init"
        #fi
    else
        echo "${SCRIPTS_DIR}/${DSTDB_TYPE}/.init.sh: skipping"    
    fi
}

# source
clear
if [ -z "${SRCDB_HOST}" ]; then ask_src_host; fi
if [ -z "${SRCDB_TYPE}" -o ! -d "${SRCDB_TYPE}" ]; then ask_src_type; fi
init_src

# destination
clear
if [ -z "${DSTDB_HOST}" ]; then ask_dst_host; fi
if [ -z "${DSTDB_TYPE}" -o ! -d "${DSTDB_TYPE}"  ]; then ask_dst_type; fi
init_dst

# set replication type
clear
if [ -z "${REPL_TYPE}" ]; then ask_repl_mode; fi
echo ${REPL_TYPE}

# LOGDIR required by copy_yaml

# WARNING: id length max is 9
export LOG_ID=$$.${REPL_TYPE:0:3}
export LOG_DIR=/tmp/arcion/${LOG_ID}
echo ${LOG_DIR}

# set config 
copy_yaml ${SRCDB_TYPE} ${DSTDB_TYPE}

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
echo "log is at $LOG_DIR"
