#!/usr/bin/env bash 

# for non interactive demo, kill jobs after certain time has passed
TIMER=${1:-0}

# TMUX
TMUX_SESSION=arcion

ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}

# env vars that can be set to skip questions
# unset DSTDB_TYPE DSTDB_HOST
# CFG_DIR
# SRCDB_HOST
# DSTDB_HOST
# SRCDB_TYPE
# DSTDB_TYPE
# REPL_TYPE

# subsutite env var in YAML with the actual
copy_yaml() {
    local SRCDB_TYPE=$1
    local DSTDB_TYPE=$2
    mkdir -p $CFG_DIR
    for f in $SCRIPTS_DIR/$SRCDB_TYPE/src*.yaml; do 
        cat $f | envsubst > $CFG_DIR/$(basename $f) 
    done
    for f in $SCRIPTS_DIR/$DSTDB_TYPE/dst*.yaml; do 
        cat $f | envsubst > $CFG_DIR/$(basename $f) 
    done
    echo "Config at $CFG_DIR"
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
    $( arcion_param ${CFG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee delta.log
    popd
}
arcion_real() {
    pushd $ARCION_HOME
    ./bin/replicant real-time \
    $( arcion_param ${CFG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee real.log
    popd
}
arcion_full() {
    pushd $ARCION_HOME
    ./bin/replicant full \
    $( arcion_param ${CFG_DIR} ) \
    --replace-existing \
    --overwrite \
    --id $LOG_ID | tee full.log
    popd
}
arcion_snapshot() {
    pushd $ARCION_HOME
    ./bin/replicant snapshot \
    $( arcion_param ${CFG_DIR} ) \
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
    rc=0
    mkdir -p /tmp/arcion/$SRCDB_HOST
    if [ -f "${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh" ]; then
        #if [ ! -f "/tmp/arcion/$SRCDB_HOST/src.init.log" ]; then
            # NOTE: do not remove () below as that will exit this script
            ( exec ${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh ) 
            if [ ! -z "$( cat /tmp/arcion/$SRCDB_HOST/src.init.log | grep failed )" ]; then rc=1; fi  
        #else
        #    echo "/tmp/arcion/$SRCDB_HOST/src.init.log: skipping init"
        #fi
    else
        echo "${SCRIPTS_DIR}/${SRCDB_TYPE}/src.init.sh: not found. skipping"    
    fi
    return $rc
}
init_dst() {
    rc=0
    mkdir -p /tmp/arcion/$DSTDB_HOST
    if [ -f "${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sh" ]; then
        #if [ ! -f "/tmp/arcion/$DSTDB_HOST/dst.init.log" ]; then
            # NOTE: do not remove () below as that will exit this script
            ( exec ${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sh )
            if [ ! -z "$( cat /tmp/arcion/$DSTDB_HOST/dst.init.log | grep failed )" ]; then rc=1; fi
        #else
        #    echo "/tmp/arcion/$DSTDB_HOST/dst.init.log: skipping init"
        #fi
    else
        echo "${SCRIPTS_DIR}/${DSTDB_TYPE}/dst.init.sh: not found. skipping"    
    fi
    return $rc
}

# source
SRCDB_HOST_old=${SRCDB_HOST}
SRCDB_TYPE_old=${SRCDB_TYPE}
while [ 1 ]; do
    clear
    echo "Setting up Source Host and Type"
    ask=0
    if [ -z "${SRCDB_HOST}" ]; then ask=1; ask_src_host; fi
    if [ -z "${SRCDB_TYPE}" -o ! -d "${SRCDB_TYPE}" ]; then ask=1; ask_src_type; fi
    init_src
    rc=$?
    echo "Source Host: ${SRCDB_HOST}"
    echo "Source Type: ${SRCDB_TYPE}"
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            SRCDB_HOST=${SRCDB_HOST_old}
            SRCDB_TYPE=${SRCDB_TYPE_old}    
        fi
    fi
done

# destination
DSTDB_HOST_old=${DSTDB_HOST}
DSTDB_TYPE_old=${DSTDB_TYPE}
while [ 1 ]; do
    clear
    echo "Setting up Target Host and Type"
    ask=0
    if [ -z "${DSTDB_HOST}" ]; then ask=1; ask_dst_host; fi
    if [ -z "${DSTDB_TYPE}" -o ! -d "${DSTDB_TYPE}"  ]; then ask=1; ask_dst_type; fi
    init_dst
    rc=$?
    echo $rc
    echo "Destination Host: ${DSTDB_HOST}"
    echo "Destination Type: ${DSTDB_TYPE}"
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            DSTDB_HOST=${DSTDB_HOST_old}
            DSTDB_TYPE=${DSTDB_TYPE_old}    
        fi
    fi
done

# set replication type
clear
echo "Setting up Soure to Target Replication mode"
ask=0
if [ -z "${REPL_TYPE}" ]; then ask=1; ask_repl_mode; fi
echo "Replication Type: ${REPL_TYPE}"
if (( ask != 0 )); then read -rsp $'Press any key to continue...\n' -n1 key; fi

# LOGDIR required by copy_yaml
clear

# WARNING: log id length max is 9
export LOG_ID=$$.${REPL_TYPE:0:3}
export CFG_DIR=/tmp/arcion/${LOG_ID}
echo ${CFG_DIR}

# set config 
copy_yaml ${SRCDB_TYPE} ${DSTDB_TYPE}

# save the choices
cat > /tmp/ini_menu.sh <<EOF
SRCDB_TYPE=${SRCDB_TYPE}
SRCDB_HOST=${SRCDB_HOST}
DSTDB_TYPE=${DSTDB_TYPE}
DSTDB_HOST=${DSTDB_HOST}
REPL_TYPE=${REPL_TYPE}
CFG_DIR=${CFG_DIR}
LOG_ID=${LOG_ID}
EOF

# run the replication
case ${REPL_TYPE,,} in
  full)
    arcion_full &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "clear; sleep 60; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "clear; sleep 60; /scripts/ycsb.sh" Enter
    ;;
  snapshot)
    arcion_snapshot
    ;;
  delta-snapshot)
    arcion_delta &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "clear; sleep 10; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "clear; sleep 10; /scripts/ycsb.sh" Enter
    ;;
  real-time)
    arcion_real &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "clear; sleep 10; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "clear; sleep 10; /scripts/ycsb.sh" Enter
    ;;    
  *)
    echo "REPL_TYPE: ${REPL_TYPE} unsupported"
    ;;
esac
echo "cfg is at $CFG_DIR"
echo "log is at ${ARCION_HOME}/data/$LOG_ID"
