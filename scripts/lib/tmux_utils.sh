#!/usr/bin/env bash


tmux_kill_windows() {
    local TMUX_SESSION=${1}
    # clear the view windows and configure it for this run
    tmux kill-window -t ${TMUX_SESSION}:1   # yaml
    tmux kill-window -t ${TMUX_SESSION}:2   # log
    tmux kill-window -t ${TMUX_SESSION}:3   # user sql
    tmux kill-window -t ${TMUX_SESSION}:4   # root sql
    tmux kill-window -t ${TMUX_SESSION}:5   # arcveri
    tmux kill-window -t ${TMUX_SESSION}:6   # arcveri_log
    tmux kill-window -t ${TMUX_SESSION}:7   # dstat

    tmux kill-pane -t ${TMUX_SESSION}:0.3   # error
    tmux kill-pane -t ${TMUX_SESSION}:0.2   # target / ycsb
    tmux kill-pane -t ${TMUX_SESSION}:0.1   # target / ycsb
}

tmux_create_windows() {
    local TMUX_SESSION=${1}
    # create new windows but don't switch into it
    tmux new-window -d -n yaml -t ${TMUX_SESSION}:1
    tmux new-window -d -n logs -t ${TMUX_SESSION}:2
    tmux new-window -d -n user_sql -t ${TMUX_SESSION}:3
    tmux new-window -d -n root_sql -t ${TMUX_SESSION}:4
    tmux new-window -d -n verificator -t ${TMUX_SESSION}:5
    tmux new-window -d -n veri_log -t ${TMUX_SESSION}:6
    tmux new-window -d -n dstat -t ${TMUX_SESSION}:7

    # windows 0 to run commands
    tmux split-window -v -t $WIN:0  # source / tpcc 
    tmux split-window -v -t $WIN:0 -p 66 # target / ycsb 
    tmux split-window -v -t $WIN:0  # trace log err

    # windows 3 user sql split
    tmux split-window -d -v -t  ${TMUX_SESSION}:3

    # windows 4 root sql split
    tmux split-window -d -v -t  ${TMUX_SESSION}:4
}

tmux_show_tpcc() {
    tmux send-keys -t ${TMUX_SESSION}:0.1 "clear; figlet -t "benchbase"; sleep 5; /scripts/bin/benchbase-run.sh" Enter
}

tmux_show_ycsb() {
    tmux send-keys -t ${TMUX_SESSION}:0.2 "clear; figlet -t ycsb; sleep 5; /scripts/bin/ycsb-run.sh" Enter
}

tmux_show_errorlog() {
    tmux send-keys -t ${TMUX_SESSION}:0.3 "figlet -t errlog; while [ ! -f ${CFG_DIR}/${LOG_ID}/error_trace.log ]; do sleep 1; done; cd ${CFG_DIR}/${LOG_ID}; tail -f error_trace.log" Enter

}

tmux_show_verification() {
    local TMUX_SESSION=${1}

    tmux send-keys -t ${TMUX_SESSION}:5.0 ". /tmp/ini_menu.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:5.0 ". lib/jdbc_cli.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:5.0 "# cd /scripts; ./arcveri.sh $CFG_DIR" Enter
    tmux send-keys -t ${TMUX_SESSION}:6.0 "while [ ! -d $VERIFICATOR_HOME/data ]; do sleep 1; done; view $VERIFICATOR_HOME/data" Enter 
}

# setup the views to look at log and cfg

tmux_show_yaml()  {
    local TMUX_SESSION=${1}

    tmux send-keys -t ${TMUX_SESSION}:1.0 "view ${CFG_DIR}" Enter
    tmux send-keys -t ${TMUX_SESSION}:1.0 ":E" Enter 
}

# the log dir does not get create right away.  wait for it.
tmux_show_trace()  {
    local TMUX_SESSION=${1}

    tmux send-keys -t ${TMUX_SESSION}:2.0 "while [ ! -f ${CFG_DIR}/${LOG_ID}/trace.log ]; do sleep 1; done; cd ${CFG_DIR}/${LOG_ID}; tail -f trace.log" Enter
}

tmux_show_console()  {
    local TMUX_SESSION=${1}
    # back to the conole
    tmux select-window -t ${TMUX_SESSION}:0.0
}

tmux_show_workload()  {
    local TMUX_SESSION=${1}

    # setup the views to look at log and cfg
    tmux_show_yaml

    # dstat
    tmux send-keys -t ${TMUX_SESSION}:7.0 "dstat --all -lmpt --noheaders --noupdate -o $CFG_DIR/dstat.csv" Enter 

    # verification
    tmux_show_verification

    # back to the conole
    tmux select-window -t ${TMUX_SESSION}:0.0
}

tmux_show_src_sql_cli() {
    tmux send-keys -t :3.0  "figlet -t src user; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_src" enter
    tmux send-keys -t :4.0  "figlet -t src root; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_root_cli_src" enter
}

tmux_show_dst_sql_cli() {
    # the dst somtimes cannot get ready to accept connection right away
    tmux send-keys -t :3.1  "figlet -t dst user; sleep 5; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_dst" enter
    tmux send-keys -t :4.1  "figlet -t dst root; sleep 5; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_root_cli_dst" enter
}


tmux_show_arcion_cli_tail() {
  local TMUX_SESSION=${1}
  local counter=0

  echo $CFG_DIR
  echo tracing the log
  # back to the conole
  tmux select-window -t ${TMUX_SESSION}:0.0

  while [ ! -f $CFG_DIR/arcion.log ]; do
    sleep 1
    echo "waiting for arcion to start"
    counter=$((counter + 1))
    if (( counter > 10 )); then
      return 1
    fi
  done
  tail -f $CFG_DIR/arcion.log &

}

# init source
tmux_run_init_src() {
  tmux send-keys -t :0.1  ". /tmp/ini_menu.sh; . /scripts/lib/arcion_utils.sh; init_src ${SRCDB_TYPE} ${SRCDB_GRP}" enter
  while [ ! -f  $CFG_DIR/exit_status/init_src.log ]; do
    sleep 1
  done
}

# init destiantion
tmux_run_init_dst() {
  tmux send-keys -t :0.2  ". /tmp/ini_menu.sh; . /scripts/lib/arcion_utils.sh; init_dst ${DSTDB_TYPE} ${DSTDB_GRP}" enter
  while [ ! -f  $CFG_DIR/exit_status/init_dst.log ]; do
    sleep 1
  done
}
