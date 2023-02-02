#!/usr/bin/env bash 

# for non interactive demo, kill jobs after certain time has passed
TIMER=${1:-0}

# TMUX
TMUX_SESSION=arcion

SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

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
    for f in $SCRIPTS_DIR/$SRCDB_TYPE/src*.yaml $SCRIPTS_DIR/$DSTDB_TYPE/dst*.yaml; do 
        cat $f | PID=$$ envsubst > $CFG_DIR/$(basename $f) 
    done
    echo "Config at $CFG_DIR"
}

infer_dbtype() {
    local DB_HOST=${1}
    local DB_TYPE=${2}
    if [ -z "${DB_HOST}" ]; then
        echo '$1 should be DB_HOST'
        return 1
    fi
    if [ -z "${DB_TYPE}" ]; then 
        # infer srcdb type from the frist word of ${SRCDB_HOST}
        DB_TYPE=$( echo ${DB_HOST} | awk -F'[-.]' '{print $1}' )
        if [ -d ${SCRIPTS_DIR}/${DB_TYPE} ]; then
            echo "$DB_TYPE"
            echo "$DB_TYPE inferred from hostname." >&2
        else
            echo "DB_TYPE was not specifed and could not infer from HOSTNAME." >&2
            return 1
        fi
    else
        echo ${DB_TYPE}
    fi
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

    dst_schemas=$(find ${dst_dir} -maxdepth 1 -name dst.init.arcsrc.sql -print)

    echo ${src} ${dst} ${filter+'--filter' $filter} ${extractor+'--extractor' $extractor} ${applier+'--applier' $applier} 
}
logreader_path() {
    case "$DSTDB_TYPE" in
        mysql)
            echo "/opt/mysql/usr/bin:$PATH"
            ;;
        mariadb)
            echo "/opt/mariadb/usr/bin:$PATH"
            ;;
        *)
            echo $PATH
            ;;
    esac
}
arcion_delta() {
    pushd $ARCION_HOME
    PATH=$( logreader_path ) ./bin/replicant delta-snapshot \
    $( arcion_param ${CFG_DIR} ) \
    --truncate-existing \
    --overwrite \
    --id $LOG_ID | tee delta.log
    popd
}
arcion_real() {
    pushd $ARCION_HOME
    PATH=$( logreader_path ) ./bin/replicant real-time \
    $( arcion_param ${CFG_DIR} ) \
    --truncate-existing \
    --overwrite \
    --id $LOG_ID | tee real.log
    popd
}
arcion_full() {
    pushd $ARCION_HOME
    PATH=$( logreader_path ) ./bin/replicant full \
    $( arcion_param ${CFG_DIR} ) \
    --truncate-existing \
    --overwrite \
    --id $LOG_ID | tee full.log
    popd
}
arcion_snapshot() {
    pushd $ARCION_HOME
    PATH=$( logreader_path ) ./bin/replicant snapshot \
    $( arcion_param ${CFG_DIR} ) \
    --truncate-existing \
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
    if [ -z "${SRCDB_TYPE}" ]; then export SRCDB_TYPE=$( infer_dbtype "${SRCDB_HOST}" ); fi
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
    if [ -z "${DSTDB_TYPE}" ]; then export DSTDB_TYPE=$( infer_dbtype "${DSTDB_HOST}" ); fi
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
export SRCDB_TYPE=${SRCDB_TYPE}
export SRCDB_HOST=${SRCDB_HOST}
export DSTDB_TYPE=${DSTDB_TYPE}
export DSTDB_HOST=${DSTDB_HOST}
export REPL_TYPE=${REPL_TYPE}
export CFG_DIR=${CFG_DIR}
export LOG_ID=${LOG_ID}
EOF

# clear the view windows and configure it for this run
tmux kill-window -t ${TMUX_SESSION}:1   # yaml
tmux kill-window -t ${TMUX_SESSION}:2   # log
tmux kill-window -t ${TMUX_SESSION}:3   # sysbench
tmux kill-window -t ${TMUX_SESSION}:4   # ycsb
# create new windows but don't switch into it
tmux new-window -d -n yaml -t ${TMUX_SESSION}:1
tmux new-window -d -n logs -t ${TMUX_SESSION}:2
tmux new-window -d -n sysbench -t ${TMUX_SESSION}:3
tmux new-window -d -n ycsb -t ${TMUX_SESSION}:4
# clear the sysbench and ycsb panes
tmux send-keys -t ${TMUX_SESSION}:0.1 "clear" Enter
tmux send-keys -t ${TMUX_SESSION}:0.2 "clear" Enter

# run the replication
case ${REPL_TYPE,,} in
  full)
    arcion_full &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 10; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 10; /scripts/ycsb.sh" Enter
    ;;
  snapshot)
    arcion_snapshot &
    ;;
  delta-snapshot)
    arcion_delta &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 10; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 10; /scripts/ycsb.sh" Enter
    ;;
  real-time)
    arcion_real &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 10; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 10; /scripts/ycsb.sh" Enter
    ;;    
  *)
    echo "REPL_TYPE: ${REPL_TYPE} unsupported"
    ;;
esac

# setup the views to look at log and cfg
tmux send-keys -t ${TMUX_SESSION}:1.0 "view ${CFG_DIR}" Enter
tmux send-keys -t ${TMUX_SESSION}:1.0 ":E" Enter 

# the log dir does not get create right away.  wait for it.
tmux send-keys -t ${TMUX_SESSION}:2.0 "sleep 5; view ${ARCION_HOME}/data/${LOG_ID}" Enter
tmux send-keys -t ${TMUX_SESSION}:2.0 ":E" Enter 

# show sysbench and ycsb changes 
tmux send-keys -t ${TMUX_SESSION}:3.0 "cd /scripts; ./verify.sysbench.sh" Enter
tmux send-keys -t ${TMUX_SESSION}:4.0 "cd /scripts; ./verify.ycsb.sh" Enter 

tmux select-window -t ${TMUX_SESSION}:0.0

# wait for jobs to finish for ctrl-c to exit
control_c() {
    tmux send-keys -t ${TMUX_SESSION}:0.1 send-keys C-c
    tmux send-keys -t ${TMUX_SESSION}:0.2 send-keys C-c
    for pid in $(jobs -p); do
        echo kill -9 $pid
        kill -9 $pid 2>/dev/null
    done
}
trap control_c SIGINT
JOBS_CNT=1
while (( JOBS_CNT != 0 )); do
    # jobs exist?
    JOBS_CNT=0
    JOBS=$(jobs -p)
    for pid in $JOBS; do
        if (( $(ps $pid | wc -l) > 1 )); then
            JOBS_CNT=$(( JOBS_CNT + 1 )) 
        fi
    done
    if (( JOBS_CNT > 0 )); then
        sleep 1
    else
        break
    fi
done

echo "cfg is at $CFG_DIR"
echo "log is at ${ARCION_HOME}/data/$LOG_ID"
