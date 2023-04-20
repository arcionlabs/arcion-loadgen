#!/usr/bin/env bash 

# source in libs
# ${BASH_SOURCE[0]} is "" if . or sourced.  otherwise, it has values
PROG_DIR=$(dirname "${BASH_SOURCE[0]}")
[ -z "${PROG_DIR}" ] && PROG_DIR=${SCRIPTS_DIR} 
. $PROG_DIR/lib/arcdemo_args.sh
. $PROG_DIR/lib/arcion_thread_ratio.sh
. $PROG_DIR/lib/uri_parser.sh
. $PROG_DIR/lib/job_control.sh
. $PROG_DIR/lib/ini_jdbc.sh
. $PROG_DIR/lib/map_csv.sh
. $PROG_DIR/lib/copy_hier_file.sh
. $PROG_DIR/lib/map_csv.sh
. $PROG_DIR/lib/arcion_utils.sh
. $PROG_DIR/lib/export_env.sh
. $PROG_DIR/lib/arcdemo_args_positional.sh

# process args advance the args to positional
arcdemo_opts $*
shift $(( OPTIND - 1 ))

if [ ! -z "$CFG_DIR" ]; then
  echo "Loading $CFG_DIR/ini_menu.sh"
  . $CFG_DIR/ini_menu.sh
else
  # this will parse the URI and set src and dst
  arcdemo_positional $*
  # validate the flag arguments
  parse_arcion_thread_ratio

  # metadata can be set to "" to not use metadata.
  # test is used to make sure METADATA_DIR is not set
  if test "${METADATA_DIR-default value}" ; then 
      METADATA_DIR=postgresql_metadata
      echo "Info: using default ${SCRIPTS_DIR}/postgresql_metadata" 
  fi

  # defaults
  SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
  ARCION_HOME=${ARCION_HOME:-/arcion}
  if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi
  export CONFLUENT_KEY_SECRET="`echo -n \"$CONFLUENT_CLUSTER_API_KEY:$CONFLUENT_CLUSTER_API_SECRET\" | base64 -w 0`"

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
  export CFG_DIR=/tmp/arcion/$(echo "${SRCDB_HOST}-${DSTDB_HOST}-${REPL_TYPE}" | tr '/' '-')-${LOG_ID}
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

  # setup the JDBC env vars
  set_jdbc_vars

  # set config 
  copy_yaml "${SRCDB_DIR}" "${SRCDB_GRP}" "${SRCDB_TYPE}" "${DSTDB_DIR}"  "${DSTDB_GRP}" "${DSTDB_TYPE}"

  # save the choices in /tmp/init_menu.sh and $CFG_DIR/ini_menu.sh
  export_env /tmp/ini_menu.sh $CFG_DIR

  # run init scripts
  init_src "${SRCDB_TYPE}" "${SRCDB_GRP}"
  rc=$?
  echo init_src rc=$rc

  init_dst "${DSTDB_TYPE}" "${DSTDB_GRP}"
  rc=$?
  echo init_dst rc=$rc

fi  

# clear the view windows and configure it for this run
tmux kill-window -t ${TMUX_SESSION}:1   # yaml
tmux kill-window -t ${TMUX_SESSION}:2   # log
tmux kill-window -t ${TMUX_SESSION}:3   # benchbase
tmux kill-window -t ${TMUX_SESSION}:4   # ycsb
tmux kill-window -t ${TMUX_SESSION}:5   # arcveri
tmux kill-window -t ${TMUX_SESSION}:6   # arcveri_log
tmux kill-window -t ${TMUX_SESSION}:7   # dstat

# create new windows but don't switch into it
tmux new-window -d -n yaml -t ${TMUX_SESSION}:1
tmux new-window -d -n logs -t ${TMUX_SESSION}:2
tmux new-window -d -n benchbase -t ${TMUX_SESSION}:3
tmux new-window -d -n ycsb -t ${TMUX_SESSION}:4
tmux new-window -d -n verificator -t ${TMUX_SESSION}:5
tmux new-window -d -n veri_log -t ${TMUX_SESSION}:6
tmux new-window -d -n dstat -t ${TMUX_SESSION}:7

# clear the benchbase and ycsb panes
tmux send-keys -t ${TMUX_SESSION}:0.1 "clear" Enter
tmux send-keys -t ${TMUX_SESSION}:0.2 "clear" Enter

function tmux_bb_panel() {
    tmux send-keys -t ${TMUX_SESSION}:0.1 "banner tpcc; sleep 5; /scripts/bin/benchbase-run.sh" Enter
}

function tmux_ycsb_panel() {
    tmux send-keys -t ${TMUX_SESSION}:0.2 "banner ycsb; sleep 5; /scripts/ycsb.sh" Enter
}
# run the replication
case ${REPL_TYPE,,} in
  full)
    arcion_full
    tmux_bb_panel
    tmux_ycsb_panel
    ;;
  snapshot)
    arcion_snapshot
    ;;
  delta-snapshot)
    arcion_delta
    tmux_bb_panel
    tmux_ycsb_panel
    ;;
  real-time)
    arcion_real
    tmux_bb_panel
    tmux_ycsb_panel
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

# with benchbase too many tables for this.  offline validate
# show sysbench and ycsb changes 
#/scripts/verify.sh id sbtest1 3 &
#/scripts/verify.sh ycsb_key usertable 4 & 

# show verificator
tmux send-keys -t ${TMUX_SESSION}:5.0 ". /tmp/ini_menu.sh" Enter
tmux send-keys -t ${TMUX_SESSION}:5.0 ". lib/jdbc_cli.sh" Enter
tmux send-keys -t ${TMUX_SESSION}:5.0 "# cd /scripts; ./arcveri.sh $CFG_DIR" Enter
tmux send-keys -t ${TMUX_SESSION}:6.0 "vi $VERIFICATOR_HOME/data" Enter 

# dstat
tmux send-keys -t ${TMUX_SESSION}:7.0 "dstat | tee $CFG_DIR/dstat.log" Enter 

# back to the conole
tmux select-window -t ${TMUX_SESSION}:0.0

# wait for jobs to finish for ctrl-c to exit
control_c() {
    tmux send-keys -t :0.1 C-c
    tmux send-keys -t :0.2 C-c
    tmux send-keys -t :7.0 C-c
    tmux select-pane -t :0.0  # ycsb
    # give chance to quiet down
    echo "Waiting 5 sec for CDC to finish" >&2
    sleep 5
    kill_jobs
}

# allow ctl-c to terminate background jobs
trap control_c SIGINT
if [ -f $CFG_DIR/arcion.log ]; then
  tail -f $CFG_DIR/arcion.log &
fi

# wait for background jobs to finish
jobs_left=$( wait_jobs "$workload_timer" "$ARCION_PID" )
control_c

echo "cfg is at $CFG_DIR"
echo "log is at ${ARCION_HOME}/data/$LOG_ID"
