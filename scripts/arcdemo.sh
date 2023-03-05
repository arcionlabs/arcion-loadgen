#!/usr/bin/env bash 

# source in libs
# ${BASH_SOURCE[0]} is "" if . or sourced.  otherwise, it has values
PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
[ -z "${PROG_DIR}" ] && PROG_DIR=${SCRIPTS_DIR} 
. $PROG_DIR/lib/arcdemo_args.sh
. $PROG_DIR/lib/arcion_thread_ratio.sh
. $PROG_DIR/lib/uri_parse.sh
. $PROG_DIR/lib/job_control.sh
. $PROG_DIR/lib/ini_jdbc.sh
. $PROG_DIR/lib/map_csv.sh
. $PROG_DIR/lib/copy_hier_file.sh
. $PROG_DIR/lib/map_csv.sh
. $PROG_DIR/lib/arcion_utils.sh

# process args advance the args to positional
arcdemo_opts $*
shift $(( OPTIND - 1 ))

# validate the flag arguments
parse_arcion_thread_ratio

# metadata can be set to "" to not use metadata.
# test is used to make sure METADATA_DIR is not set
if test "${METADATA_DIR-default value}" ; then 
    METADATA_DIR=postgresql_metadata
    echo "Info: using default ${SCRIPTS_DIR}/postgresql_metadata" 
fi

# default
SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
ARCION_HOME=${ARCION_HOME:-/arcion}
if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi




# set REPL_TYPE from command line
if [ ! -z "$1" ]; then 
    REPL_TYPE=$1; 
fi

# set from SRC URI command line
if [ ! -z "$2" ]; then 
    uri_parser "$2"
    [ "${uri_schema}" ] && export SRCDB_TYPE=${uri_schema} 
    [ "${uri_user}" ] && export SRCDB_ARC_USER=${uri_user}
    [ "${uri_password}" ] && export SRCDB_ARC_PW=${uri_password}
    [ "${uri_host}" ] && export SRCDB_HOST=${uri_host}
    [ "${uri_port}" ] && export SRCDB_PORT=${uri_port}
    [ "${uri_path}" ] && export SRCDB_SUBDIR=${uri_path}
fi

# set from DST URL command line
if [ ! -z "$3" ]; then
    uri_parser "$3"
    [ "${uri_schema}" ] && export DSTDB_TYPE=${uri_schema} 
    [ "${uri_user}" ] && export DSTDB_ARC_USER=${uri_user}
    [ "${uri_password}" ] && export DSTDB_ARC_PW=${uri_password}
    [ "${uri_host}" ] && export DSTDB_HOST=${uri_host}
    [ "${uri_port}" ] && export DSTDB_PORT=${uri_port}
    [ "${uri_path}" ] && export DSTDB_SUBDIR=${uri_path}
fi

export SRCDB_ARC_USER=${SRCDB_ARC_USER:-arcsrc}
export SRCDB_ARC_PW=${SRCDB_ARC_PW:-Passw0rd}

export DSTDB_ARC_USER=${DSTDB_ARC_USER:-arcdst}
export DSTDB_ARC_PW=${DSTDB_ARC_PW:-Passw0rd}

# env vars that can be set to skip questions
# unset DSTDB_DIR DSTDB_HOST
# CFG_DIR
# SRCDB_HOST
# DSTDB_HOST
# SRCDB_DIR
# DSTDB_DIR
# REPL_TYPE

# these are from arc_utils.sh
set_src
set_dst

# WARNING: log id length max is 9
export LOG_ID=$$
export CFG_DIR=/tmp/arcion/${LOG_ID}_$(echo "${SRCDB_HOST}_${DSTDB_HOST}_${REPL_TYPE}" | tr '/' '_')
mkdir -p $CFG_DIR
echo $CFG_DIR   

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
copy_yaml "${SRCDB_DIR}" "${SRCDB_GRP}" "${SRCDB_TYPE}" "${DSTDB_DIR}"  "${DSTDB_GRP}" "${DSTDB_TYPE}"

# setup the JDBC env vars
set_jdbc_vars

# save the choices in /tmp/init_menu.sh and $CFG_DIR/ini_menu.sh
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
# JDBC
export SRCDB_JDBC_DRIVER="$SRCDB_JDBC_DRIVER"
export SRCDB_JDBC_URL="$SRCDB_JDBC_URL"
export SRCDB_JDBC_URL_IDPW="$SRCDB_JDBC_URL_IDPW"
export SRCDB_ROOT_URL="$SRCDB_ROOT_URL"
export DSTDB_JDBC_DRIVER="$DSTDB_JDBC_DRIVER"
export DSTDB_JDBC_URL="$DSTDB_JDBC_URL"
export DSTDB_JDBC_URL_IDPW="$DSTDB_JDBC_URL_IDPW"
export DSTDB_ROOT_URL="$DSTDB_ROOT_URL"
# JSQSH
export SRCDB_JSQSH_DRIVER="$SRCDB_JSQSH_DRIVER"
export DSTDB_JSQSH_DRIVER="$DSTDB_JSQSH_DRIVER"
# YCSB
export SRCDB_YCSB_DRIVER="$SRCDB_YCSB_DRIVER"
export DSTDB_YCSB_DRIVER="$DSTDB_YCSB_DRIVER"
# SCHEMA
export SRCDB_SCHEMA=${SRCDB_SCHEMA}
export SRCDB_COMMA_SCHEMA=${SRCDB_COMMA_SCHEMA}
export DSTDB_SCHEMA=${DSTDB_SCHEMA}
export DSTDB_COMMA_SCHEMA=${DSTDB_COMMA_SCHEMA}
# THREADS
export SRCDB_SNAPSHOT_THREADS=${SRCDB_SNAPSHOT_THREADS}
export SRCDB_REALTIME_THREADS=${SRCDB_REALTIME_THREADS}
export SRCDB_DELTA_SNAPSHOT_THREADS=${SRCDB_DELTA_SNAPSHOT_THREADS}
export DSTDB_SNAPSHOT_THREADS=${DSTDB_SNAPSHOT_THREADS}
export DSTDB_REALTIME_THREADS=${DSTDB_REALTIME_THREADS}
# workload control
export max_cpus="$max_cpus"
export workload_rate="$workload_rate"
export workload_threads="$workload_threads"
export workload_timer="$workload_timer"
export workload_size_factor="$workload_size_factor"
EOF
cp /tmp/ini_menu.sh $CFG_DIR/.

# run init scripts
init_src "${SRCDB_TYPE}" "${SRCDB_GRP}"
rc=$?
echo init_src rc=$rc

init_dst "${DSTDB_TYPE}" "${DSTDB_GRP}"
rc=$?
echo init_dst rc=$rc

# clear the view windows and configure it for this run
tmux kill-window -t ${TMUX_SESSION}:1   # yaml
tmux kill-window -t ${TMUX_SESSION}:2   # log
tmux kill-window -t ${TMUX_SESSION}:3   # sysbench
tmux kill-window -t ${TMUX_SESSION}:4   # ycsb
tmux kill-window -t ${TMUX_SESSION}:5   # arcveri
tmux kill-window -t ${TMUX_SESSION}:6   # arcveri_log

# create new windows but don't switch into it
tmux new-window -d -n yaml -t ${TMUX_SESSION}:1
tmux new-window -d -n logs -t ${TMUX_SESSION}:2
tmux new-window -d -n sysbench -t ${TMUX_SESSION}:3
tmux new-window -d -n ycsb -t ${TMUX_SESSION}:4
tmux new-window -d -n verificator -t ${TMUX_SESSION}:5
tmux new-window -d -n veri_log -t ${TMUX_SESSION}:6
# clear the sysbench and ycsb panes
tmux send-keys -t ${TMUX_SESSION}:0.1 "clear" Enter
tmux send-keys -t ${TMUX_SESSION}:0.2 "clear" Enter

# run the replication
case ${REPL_TYPE,,} in
  full)
    arcion_full &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 1; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 1; /scripts/ycsb.sh" Enter
    ;;
  snapshot)
    arcion_snapshot &
    ;;
  delta-snapshot)
    arcion_delta &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 1; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 1; /scripts/ycsb.sh" Enter
    ;;
  real-time)
    arcion_real &
    tmux send-keys -t ${TMUX_SESSION}:0.1 "sleep 1; /scripts/sysbench.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:0.2 "sleep 1; /scripts/ycsb.sh" Enter
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
tmux send-keys -t ${TMUX_SESSION}:3.0 "cd /scripts; ./verify.sh id sbtest1 3" Enter
tmux send-keys -t ${TMUX_SESSION}:4.0 "cd /scripts; ./verify.sh ycsb_key usertable 4" Enter 

# show verificator
tmux send-keys -t ${TMUX_SESSION}:5.0 "# cd /scripts; ./arcveri.sh $CFG_DIR" Enter
tmux send-keys -t ${TMUX_SESSION}:6.0 "vi $VERIFICATOR_HOME/data" Enter 

# 
tmux select-window -t ${TMUX_SESSION}:0.0

# wait for jobs to finish for ctrl-c to exit
control_c() {
    # send first time
    tmux send-keys -t ${TMUX_SESSION}:0.1 send-keys C-c
    tmux send-keys -t ${TMUX_SESSION}:0.2 send-keys C-c
    # send second time
    tmux send-keys -t ${TMUX_SESSION}:0.1 send-keys C-c
    tmux send-keys -t ${TMUX_SESSION}:0.2 send-keys C-c
    # kill jobs from this pane
    kill_jobs
}

# allow ctl-c to terminate background jobs
trap control_c SIGINT

# wait for background jobs to finish
wait_jobs

echo "cfg is at $CFG_DIR"
echo "log is at ${ARCION_HOME}/data/$LOG_ID"
