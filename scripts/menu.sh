#!/usr/bin/env bash 

# thread to match the CPUs on the system
export CPUS=${CPUS:-$(getconf _NPROCESSORS_ONLN)}
if [ -z "$CPUS" ]; then CPUS=1; fi

# for non interactive demo, kill jobs after certain time has passed
TIMER=${1:-0}

# TMUX
export TMUX_SESSION=arcion

# metadata can be set to "" to not use metadata.
# test is used to make sure METADATA_DIR is not set
if test "${METADATA_DIR-default value}" ; then 
    METADATA_DIR=postgresql_metadata
    echo "Info: using default ${SCRIPTS_DIR}/postgresql_metadata" 
fi

# arcion replicant command line flag
# ARCION_ARGS=${ARCION_ARGS:-"--truncate-existing --overwrite --verbose"}
# does not work on apple silicon w/ mysql to mysql
ARCION_ARGS=${ARCION_ARGS:-"--replace-existing --overwrite --verbose"}

# default
SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi

# env vars that can be set to skip questions
# unset DSTDB_DIR DSTDB_HOST
# CFG_DIR
# SRCDB_HOST
# DSTDB_HOST
# SRCDB_DIR
# DSTDB_DIR
# REPL_TYPE

map_db() {
    local DB_TYPE=${1}
    local COLUMN_INDEX=${2:-2}  
    local COLUMN_VALUE
    # column position in the map.csv
    # type(1),group(2),default_port(3),root_user(4),root_pw(5)
    if [ -f "${SCRIPTS_DIR}/utils/map.csv" ]; then 
        ROW=$(grep "^${DB_TYPE}," ${SCRIPTS_DIR}/utils/map.csv | head -n 1)
        COLUMN_VALUE=$(echo ${ROW} | cut -d',' -f${COLUMN_INDEX})
    fi
    if [ -z "${ROW}" ]; then 
        echo "Error: $1 not defined in map.csv." >&2
    fi
    echo $COLUMN_VALUE
}
map_dbtype() {
    local DB_DIR=${1}
    DB_TYPE=$( echo $DB_DIR | awk -F'[_-/.]' '{print $1}' )
    echo "${DB_TYPE}"
}
map_dbgrp() {
    map_db "$1" 2
}
map_dbport() {
    map_db "$1" 3
}
map_dbroot() {
    map_db "$1" 4
}
map_dbrootpw() {
    map_db "$1" 5
}

copy_hier_as_flat() {
    local SRC=${1:-"./"}
    local PREFIX=$2
    local DST=${3:-/tmp/$(basename $(realpath $SRC))}
    [ ! -d "${DST}" ] && mkdir -p ${DST}
    dir=""
    for d in $( echo $SRC |  tr "/" "\n" ); do
        echo "*${d}"
        dir="${dir}${d}"
        if [ ! -d "${dir}" ]; then continue; fi
        for f in $( find $dir -maxdepth 1 -type f -name $PREFIX\*.yaml -o -name $PREFIX\*.sh -o -name $PREFIX\*.sql -o -name $PREFIX\*.js ); do
            filename=$(basename $f)
            if [ -f $DST/$filename ]; then
                echo override $f $DST/$filename
            else
                echo cp $f $DST/$filename
            fi 
            cat "${f}" | PID=$$ envsubst > $DST/$filename
        done
        dir="${dir}/"
    done
}

copy_yaml() {
    local SRCDB_DIR="$1"
    local DSTDB_DIR="$2"
    local DSTDB_GRP="$3"
    local DSTDB_TYPE="$4"
    local PID

    [ -z "$SRCDB_DIR" ] && echo "copy_yaml: SRCDB_DIR is blank" >&2
    [ -z "$DSTDB_DIR" ] && echo "copy_yaml: DSTDB_DIR is blank" >&2
    [ -z "$DSTDB_GRP" ] && echo "copy_yaml: DSTDB_GRP is blank" >&2
    [ -z "$DSTDB_TYPE" ] && echo "copy_yaml: DSTDB_TYPE is blank" >&2

    # copy the src and dst configs into a flat dir
    pushd $SCRIPTS_DIR
    copy_hier_as_flat $SRCDB_DIR src $CFG_DIR
    copy_hier_as_flat $DSTDB_DIR dst $CFG_DIR
    copy_hier_as_flat $METADATA_DIR meta $CFG_DIR
    popd

    # override the destionation specific
    if [ -d $SRCDB_DIR/src_dst_map ]; then
        pushd $SRCDB_DIR/src_dst_map
        copy_hier_as_flat $DSTDB_GRP/$DSTDB_TYPE/ src $CFG_DIR
        popd
    fi

    echo "Config at $CFG_DIR"
}

infer_dbdir() {
    local DB_HOST=${1}
    local DB_DIR=${2}
    if [ -z "${DB_HOST}" ]; then
        echo '$1 should be DB_HOST'
        return 1
    fi
    if [ -z "${DB_DIR}" ]; then 
        # infer srcdb type from the frist word of ${SRCDB_HOST}
        DB_DIR=$( echo ${DB_HOST} | awk -F'[-.]' '{print $1}' )
        if [ -d ${SCRIPTS_DIR}/${DB_DIR} ]; then
            echo "$DB_DIR inferred from hostname." >&2
            echo "$DB_DIR"
        else
            echo "DB_DIR was not specifed and could not infer from HOSTNAME." >&2
            return 1
        fi
    else
        echo ${DB_DIR}
    fi
}

# return command parm given source and target pair
arcion_param() {
    local src_dir=${1:-.}
    local dst_dir=${2:-$src_dir}
    local meta_dir=${3:-$src_dir}
    local arg=""

    # source specific
    src=$(find ${src_dir} -maxdepth 1 -name src.yaml -print)
    filter=$(find ${src_dir} -maxdepth 1 -name src_filter.yaml -print)
    extractor=$(find ${src_dir} -maxdepth 1 -name src_extractor.yaml -print)

    # dest specific
    dst=$(find ${dst_dir} -maxdepth 1 -name dst.yaml -print)
    applier=$(find ${dst_dir} -maxdepth 1 -name dst_applier.yaml -print)

    # optional
    map=$(find ${dst_dir} -maxdepth 1 -name src_map.yaml -print)
    metadata=$(find ${meta_dir} -maxdepth 1 -name metadata.yaml -print)

    # construct the list
    arg="${src} ${dst}"
    [ ! -z "${filter}" ] && arg="${arg} --filter ${filter}"
    [ ! -z "${extractor}" ] && arg="${arg} --extractor ${extractor}"
    [ ! -z "${applier}" ] && arg="${arg} --applier ${applier}"
    [ ! -z "${map}" ] && arg="${arg} --map ${map}"
    [ ! -z "${metadata}" ] && arg="${arg} --metadata ${metadata}"

    echo "$arg" 
}
logreader_path() {
    local SRCDB_TYPE=${1}
    case "${SRCDB_TYPE,,}" in
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
    PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant delta-snapshot \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
    --id $LOG_ID | tee delta.log
    popd
}
arcion_real() {
    pushd $ARCION_HOME
    PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant real-time \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
    --id $LOG_ID | tee real.log
    popd
}
arcion_full() {
    pushd $ARCION_HOME
    PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant full \
    $( arcion_param ${CFG_DIR} ) \
     ${ARCION_ARGS} \
    --id $LOG_ID | tee full.log
    popd
}
arcion_snapshot() {
    pushd $ARCION_HOME
    echo "$( arcion_param ${CFG_DIR} )"
    PATH=$( logreader_path "${SRCDB_TYPE}" ) ./bin/replicant snapshot \
    $( arcion_param ${CFG_DIR} ) \
    ${ARCION_ARGS} \
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
    while read count dir; do 
        if (( count == 2 )); then echo $dir; fi; 
    done
}

find_hosts() {
    mkdir -p /tmp/arcion/nmap
    if [ ! -f "/tmp/arcion/nmap/names.$$.txt" ]; then
        ip=$( hostname -i | awk -F'.' '{print $1 "." $2 "." $3 "." 0 "/24"}' )
        nmap -sn -oG /tmp/arcion/nmap/names.$$.txt $ip >/dev/null
    fi
    cat /tmp/arcion/nmap/names.$$.txt | grep "arcnet" | awk -F"[ \(\)]" '{print $4}'
}

ask_src_host() {
    PS3="Please enter the SOURCE host: "
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
ask_src_dir() {
    PS3='Please enter the source dir: '
    options=( $(find_srcdb) )
    select SRCDB_DIR in "${options[@]}"; do
        if [ -d "$SRCDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export SRCDB_DIR
}
ask_dst_dir() {
    PS3='Please enter the target: '
    options=( $(find_dstdb) )
    select DSTDB_DIR in "${options[@]}"; do
        if [ -d "$DSTDB_DIR" ]; then break; else echo "invalid option"; fi
    done
    export DSTDB_DIR
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
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0

    # src id/password
    export SRCDB_ROOT=${SRCDB_ROOT:-$( map_dbroot "$DB_TYPE" )}
    export SRCDB_PW=${SRCDB_PW:-$( map_dbrootpw "$DB_TYPE" )}
    export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
    export SRCDB_ARC_PW=${SRCDB_ARC_PW:-password}

    # find src.init.sh
    if [ -f "${SCRIPTS_DIR}/${SRCDB_DIR}/src.init.sh" ]; then
        DB_INIT=${SCRIPTS_DIR}/${SRCDB_DIR}/src.init.sh
    elif [ -f "${SCRIPTS_DIR}/utils/map.csv" ]; then 
        if [ ! -z "$DB_GRP" ] && [ -f "${SCRIPTS_DIR}/utils/${DB_GRP}/src.init.sh" ]; then
            DB_INIT=${SCRIPTS_DIR}/utils/${DB_GRP}/src.init.sh
            echo DB_INIT=${SCRIPTS_DIR}/utils/${DB_GRP}/src.init.sh
        fi
    fi

    # run src.init.sh
    if [ -f "${DB_INIT}" ]; then
            # NOTE: do not remove () below as that will exit this script
            ( exec ${DB_INIT} 2>&1 | tee -a $CFG_DIR/src.init.sh.log ) 
            if [ ! -z "$( cat $CFG_DIR/src.init.sh.log | grep -i failed )" ]; then rc=1; fi  
    else
        echo "${SCRIPTS_DIR}/${SRCDB_DIR}/src.init.sh: not found. skipping"    
    fi

    return $rc
}
init_dst() {
    local DB_TYPE="$1"
    local DB_GRP="$2"
    local DB_INIT
    local DB_GRP
    local rc=0    

    # dst id/password
    export DSTDB_ROOT=${DSTDB_ROOT:-$( map_dbroot "$DB_TYPE" )}
    export DSTDB_PW=${DSTDB_PW:-$( map_dbrootpw "$DB_TYPE" )}
    export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
    export DSTDB_ARC_PW=${DSTDB_ARC_PW:-password}

    # find dst.init.sh
    if [ -f "${SCRIPTS_DIR}/${DSTDB_DIR}/dst.init.sh" ]; then
        DB_INIT=${SCRIPTS_DIR}/${DSTDB_DIR}/dst.init.sh
    elif [ -f "${SCRIPTS_DIR}/utils/map.csv" ]; then 
        if [ ! -z "$DB_GRP" ] && [ -f "${SCRIPTS_DIR}/utils/${DB_GRP}/dst.init.sh" ]; then
            DB_INIT=${SCRIPTS_DIR}/utils/${DB_GRP}/dst.init.sh
            echo DB_INIT=${SCRIPTS_DIR}/utils/${DB_GRP}/dst.init.sh
        fi
    fi

    # run dst.init.sh
    if [ -f "${DB_INIT}" ]; then
            # NOTE: do not remove () below as that will exit this script
            ( exec ${DB_INIT} 2>&1 | tee -a $CFG_DIR/dst.init.sh.log ) 
            if [ ! -z "$( cat $CFG_DIR/dst.init.sh.log | grep -i failed )" ]; then rc=1; fi  
    else
        echo "${SCRIPTS_DIR}/${DSTDB_DIR}/dst.init.sh: not found. skipping"    
    fi

    return $rc
}

# WARNING: log id length max is 9
export LOG_ID=$$
export CFG_DIR=/tmp/arcion/${LOG_ID}
mkdir -p $CFG_DIR
echo ${CFG_DIR}

# source
SRCDB_HOST_old=${SRCDB_HOST}
SRCDB_DIR_old=${SRCDB_DIR}
SRCDB_TYPE_old=${SRCDB_TYPE}
SRCDB_GRP_old=${SRCDB_GRP}
SRCDB_PORT_old=${SRCDB_PORT}
SRCDB_ROOT_old=${SRCDB_ROOT}
while [ 1 ]; do
    clear
    echo "Setting up Source Host and Type"
    ask=0
    if [ -z "${SRCDB_HOST}" ]; then ask=1; ask_src_host; fi
    if [ -z "${SRCDB_DIR}" ]; then export SRCDB_DIR=$( infer_dbdir "${SRCDB_HOST}" ); fi
    if [ -z "${SRCDB_DIR}" -o ! -d "${SRCDB_DIR}" ]; then ask=1; ask_src_dir; fi
    [ -z "${SRCDB_TYPE}" ] && export SRCDB_TYPE=$( map_dbtype "${SRCDB_DIR}" )
    [ -z "${SRCDB_GRP}" ] && export SRCDB_GRP=$( map_dbgrp "${SRCDB_TYPE}" )
    [ -z "${SRCDB_PORT}" ] && export SRCDB_PORT=$( map_dbport "${SRCDB_TYPE}" )
    [ -z "${SRCDB_ROOT}" ] && export SRCDB_ROOT=$( map_dbroot "${SRCDB_TYPE}" )
    init_src "${SRCDB_TYPE}" "${SRCDB_GRP}"
    rc=$?
    echo "Source Host: ${SRCDB_HOST}"
    echo "Source Dir: ${SRCDB_DIR}"
    echo "Source Type: ${SRCDB_TYPE}"
    echo "Source Grp: ${SRCDB_GRP}"
    echo "Source Port: ${SRCDB_PORT}"
    echo "Source Root: ${SRCDB_ROOT}"
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            SRCDB_HOST=${SRCDB_HOST_old}
            SRCDB_DIR=${SRCDB_DIR_old} 
            SRCDB_TYPE=${SRCDB_TYPE_old} 
            SRCDB_GRP=${SRCDB_GRP_old}
            SRCDB_PORT=${SRCDB_PORT_old}                
            SRCDB_ROOT=${SRCDB_ROOT_old}                
        fi
    fi
done

# destination
DSTDB_HOST_old=${DSTDB_HOST}
DSTDB_TYPE_old=${DSTDB_TYPE}
DSTDB_DIR_old=${DSTDB_DIR}
DSTDB_GRP_old=${DSTDB_GRP}
DSTDB_PORT_old=${DSTDB_PORT}
DSTDB_ROOT_old=${DSTDB_ROOT}
while [ 1 ]; do
    clear
    echo "Setting up Target Host and Type"
    ask=0
    if [ -z "${DSTDB_HOST}" ]; then ask=1; ask_dst_host; fi
    if [ -z "${DSTDB_DIR}" ]; then export DSTDB_DIR=$( infer_dbdir "${DSTDB_HOST}" ); fi
    if [ -z "${DSTDB_DIR}" -o ! -d "${DSTDB_DIR}" ]; then ask=1; ask_dst_dir; fi
    [ -z "${DSTDB_TYPE}" ] && export DSTDB_TYPE=$( map_dbtype "${DSTDB_DIR}" )
    [ -z "${DSTDB_GRP}" ] && export DSTDB_GRP=$( map_dbgrp "${DSTDB_TYPE}" )
    [ -z "${DSTDB_PORT}" ] && export DSTDB_PORT=$( map_dbport "${DSTDB_TYPE}" )
    [ -z "${DSTDB_ROOT}" ] && export DSTDB_ROOT=$( map_dbroot "${DSTDB_TYPE}" )
    init_dst "${DSTDB_TYPE}" "${DSTDB_GRP}"
    rc=$?
    echo $rc
    echo "Destination Host: ${DSTDB_HOST}"
    echo "Destination Dir: ${DSTDB_DIR}"
    echo "Destination Type: ${DSTDB_TYPE}"
    echo "Destination Grp: ${DSTDB_GRP}"
    echo "Destination Port: ${DSTDB_PORT}"    
    echo "Destination Root: ${DSTDB_ROOT}"    
    if (( ask == 0 )); then 
        break
    else
        read -rsp $'Press any key to continue...\n' -n1 key; 
        if (( rc == 0 )); then
            break;
        else
            DSTDB_HOST=${DSTDB_HOST_old}
            DSTDB_DIR=${DSTDB_DIR_old}   
            DSTDB_TYPE=${DSTDB_TYPE_old}   
            DSTDB_GRP=${DSTDB_GRP_old}
            DSTDB_PORT=${DSTDB_PORT_old}               
            DSTDB_ROOT=${DSTDB_ROOT_old}               
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


# set config 
copy_yaml "${SRCDB_DIR}" "${DSTDB_DIR}" "${DSTDB_GRP}" "${DSTDB_TYPE}"

# save the choices
cat > /tmp/ini_menu.sh <<EOF
# source
export SRCDB_DIR=${SRCDB_DIR}
export SRCDB_TYPE=${SRCDB_TYPE}
export SRCDB_HOST=${SRCDB_HOST}
export SRCDB_GRP=${SRCDB_GRP}
export SRCDB_PORT=${SRCDB_PORT}
# destination
export DSTDB_DIR=${DSTDB_DIR}
export DSTDB_TYPE=${DSTDB_TYPE}
export DSTDB_HOST=${DSTDB_HOST}
export DSTDB_GRP=${DSTDB_GRP}
export DSTDB_PORT=${DSTDB_PORT}
# replication
export REPL_TYPE=${REPL_TYPE}
export ARCION_ARGS="${ARCION_ARGS}"
# root id/password
export SRCDB_ROOT=${SRCDB_ROOT}
export SRCDB_PW=${SRCDB_PW}
export DSTDB_ROOT=${DSTDB_ROOT}
export DSTDB_PW=${DSTDB_PW}
# user id/password
export SRCDB_ARC_USER=${SRCDB_ARC_USER}
export SRCDB_ARC_PW=${SRCDB_ARC_PW}
export DSTDB_ARC_USER=${DSTDB_ARC_USER}
export DSTDB_ARC_PW=${DSTDB_ARC_PW}
# cfg
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
