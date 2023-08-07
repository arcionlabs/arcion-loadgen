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
. $PROG_DIR/lib/tmux_utils.sh
. $PROG_DIR/lib/nine_char_id.sh
. $PROG_DIR/lib/prep_arcion_log.sh
. $PROG_DIR/lib/prep_arcion_lic.sh

# wait for jobs to finish for ctrl-c to exit
control_c() {
    tmux send-keys -t :0.1 C-c
    tmux send-keys -t :0.2 C-c
    tmux send-keys -t :0.3 C-c
    tmux send-keys -t :7.0 C-c
    tmux select-pane -t :0.0  # console
    # give chance to quiet down
    echo "Waiting 5 sec for CDC to finish" >&2
    sleep 5
    kill_jobs
    kill_recurse $ARCION_PID  # required as catch all
}

exit_message() {
  control_c
  echo "cfg is at $CFG_DIR"
  echo "log is at ${ARCION_LOG}/$LOG_ID"
  echo "you can rerun with arcdemo.sh -f $CFG_DIR"
}

count_cdclog() {
  while [ ! -f $CFG_DIR/arcion.log ] && [ ! -s  $CFG_DIR/arcion.log ]; do sleep 1; done
  exitcode=$(tail -f $CFG_DIR/arcion.log | awk -v maxsnapsecs="${workload_timer}" -v maxrealsecs="${fullcdc_timer}" -f $SCRIPTS_DIR/lib/earlyexit.awk)
  rc=${PIPESTATUS[1]}
  if [[ "$rc" != "0" ]]; then  
    banner "earlyexit"
    exit_message 
  fi
}

cd "${SCRIPTS_DIR}" || exit 1

# prep arcion_log
prep_arcion_log # prep_arcion_log.sh

# prep arcion licese
prep_arcion_lic # prep_arcion_lic.sh

# prep the jar files
for f in $(find /opt/stage/libs/*.jar -printf "%f\n"); do
  if [ ! -f $ARCION_HOME/lib/ ]; then 
    echo cp /opt/stage/libs/$f $ARCION_HOME/lib/.
    cp /opt/stage/libs/$f $ARCION_HOME/lib/.
  fi
done

export ARCION_VER=$($ARCION_HOME/bin/replicant version 2>/dev/null | grep "^Version" | awk '{print $2}')
echo "Running Arcion $ARCION_HOME $ARCION_VER"
echo "Running Script $SCRIPTS_DIR"

# read profile (map.csv file) 
declare -a PROFILE_CSV=(); read_csv_as_array PROFILE_CSV
export PROFILE_HEADER=${PROFILE_CSV[0]}

# process args advance the args to positional
arcdemo_opts $*
shift $(( OPTIND - 1 ))

if [ -n "$CFG_DIR" ]; then
  echo "Loading $CFG_DIR/ini_menu.sh"
  . $CFG_DIR/ini_menu.sh
  # clear the view windows and configure it for this run
  tmux_kill_windows
  # create new windows but don't switch into it
  tmux_create_windows
  # show workload specific content
  tmux_show_workload
  # show src and dst sql cli
  tmux_show_src_sql_cli
  tmux_show_dst_sql_cli
else
  # this will parse the URI and set src and dst
  arcdemo_positional "$@"

  # validate the flag arguments
  parse_arcion_thread_ratio

  # get profile of src and dst
  export SRCDB_PROFILE_CSV=$( get_profile PROFILE_CSV "${SRCDB_SHORTNAME}")
  export DSTDB_PROFILE_CSV=$( get_profile PROFILE_CSV "${DSTDB_SHORTNAME}")

  if [ -z "$SRCDB_PROFILE_CSV" ]; then echo "map.csv does not contain ${SRCDB_SHORTNAME} profile"; exit 1; fi
  if [ -z "$DSTDB_PROFILE_CSV" ]; then echo "map.csv does not contain ${DSTDB_SHORTNAME} profile"; exit 1; fi

  # dict can not be exported but is available to child functions
  declare -A SRCDB_PROFILE_DICT=(); csv_as_dict SRCDB_PROFILE_DICT "${PROFILE_HEADER}" "${SRCDB_PROFILE_CSV}"
  declare -A DSTDB_PROFILE_DICT=(); csv_as_dict DSTDB_PROFILE_DICT "${PROFILE_HEADER}" "${DSTDB_PROFILE_CSV}"

  echo "PROFILE header: $PROFILE_HEADER"
  echo "SRC profile: $SRCDB_PROFILE_CSV $(declare -p SRCDB_PROFILE_DICT)"
  echo "DST profile: $DSTDB_PROFILE_CSV $(declare -p DSTDB_PROFILE_DICT)"

  # map variables from profile if any
  set_default_host_user
  
  if [ -z "${SRCDB_HOST}" ]; then ask=1; ask_src_host; fi
  if [ -z "${DSTDB_HOST}" ]; then ask=1; ask_dst_host; fi
  
  # metadata can be set to "" to not use metadata.
  # test is used to make sure METADATA_DIR is not set
  if test "${METADATA_DIR-default value}" ; then 
      # METADATA_DIR=metadata_postgresql
      METADATA_DIR=metadata_sqlite
      if [ -d "${SCRIPTS_DIR}/${METADATA_DIR}" ]; then
        echo "Info: using default ${SCRIPTS_DIR}/${METADATA_DIR}" 
      else
        echo "Error: ${SCRIPTS_DIR}/${METADATA_DIR} is not a dir"
        exit
      fi
  fi

  # defaults
  SCRIPTS_DIR=${SCRIPTS_DIR:-/scripts}
  ARCION_HOME=${ARCION_HOME:-/arcion}
  if [ -d ${ARCION_HOME}/replicant-cli ]; then ARCION_HOME=${ARCION_HOME}/replicant-cli; fi
  export CONFLUENT_KEY_SECRET="$(echo -n \"$CONFLUENT_CLUSTER_API_KEY:$CONFLUENT_CLUSTER_API_SECRET\" | base64 -w 0)"

  # env vars that can be set to skip questions
  # unset DSTDB_DIR DSTDB_HOST
  # CFG_DIR
  # SRCDB_HOST
  # DSTDB_HOST
  # SRCDB_DIR
  # DSTDB_DIR
  # REPL_TYPE

  # create tmp CFG_DIR
  mkdir -p /arcion/data
  # WARNING: log id length max is 9
  export LOG_ID="$(nine_char_id)"
  export CFG_DIR=/tmp/${LOG_ID}-${LOG_ID}
  rm -rf $CFG_DIR 2>/dev/null
  # these are from arc_utils.sh
  # src host and target host are not known at this point
  set_src
  set_dst
  # temp dirs
  mkdir -p $CFG_DIR/stage
  # oracle sqlldr has hard coded tmp
  mkdir -p $CFG_DIR/tmp
  mkdir -p $CFG_DIR/metadata

  # change the name of the CFG_DIR
  # chage /- to _ and change ' 'to - to make the name
  CFG_DIR=${ARCION_LOG}/${LOG_ID}-$(echo "${ARCION_VER} ${SRCDB_SHORTNAME} ${DSTDB_SHORTNAME} ${REPL_TYPE} ${workload_size_factor}" | tr '/-' '_' | tr ' ' '-' )
  # delete if this happen to exist already
  rm -rf $CFG_DIR 2>/dev/null
  # move to new name
  mv /tmp/${LOG_ID}-${LOG_ID} $CFG_DIR
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

  # clear the view windows and configure it for this run
  tmux_kill_windows
  # create new windows but don't switch into it
  tmux_create_windows
  # show workload specific content
  tmux_show_workload

  # run init scripts
  tmux_run_init_src &
  tmux_run_init_dst &

  # wait for source and dst setup to finish
  tmux_show_console
  show_yaml.sh
  # wait 
  wait
  # bring up src and dst SQL CLI tmux windows
  tmux_show_src_sql_cli
  tmux_show_dst_sql_cli
fi  

# exit if src or dst init failed
if [[ -n "$(grep -v "^0$" $CFG_DIR/exit_status/init_src.log)" ]]; then echo "arcdemo.sh: src init failed."; exit_message; exit 1; fi  
if [[ -n "$(grep -v "^0$" $CFG_DIR/exit_status/init_dst.log)" ]]; then echo "arcdemo.sh: dst init failed."; exit_message; exit 1; fi  

# run the replication
case ${REPL_TYPE,,} in
  full)
    arcion_full
    tmux_show_tpcc
    tmux_show_ycsb
    count_cdclog &
    ;;
  snapshot)
    arcion_snapshot
    ;;
  delta-snapshot)
    arcion_delta
    tmux_show_tpcc
    tmux_show_ycsb
    ;;
  real-time)
    arcion_real
    tmux_show_tpcc
    tmux_show_ycsb
    count_cdclog &
    ;;    
  *)
    echo "REPL_TYPE: ${REPL_TYPE} unsupported"
    ;;
esac

tmux_show_errorlog
tmux_show_trace

# display arcion progress screen
tmux_show_arcion_cli_tail

# allow ctl-c to terminate background jobs
trap control_c SIGINT

# wait for background jobs to finish
jobs_left=$( wait_jobs "$workload_timer" "$ARCION_PID" )

exit_message

