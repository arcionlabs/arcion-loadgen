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

    tmux kill-pane -t ${TMUX_SESSION}:0.2   # source / tpcc
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
    tmux split-window -v -t $WIN:0  # target / ycsb

    # windows 3 user sql split
    tmux split-window -d -v -t  ${TMUX_SESSION}:3

    # windows 4 root sql split
    tmux split-window -d -v -t  ${TMUX_SESSION}:4
}

tmux_show_tpcc() {
    tmux send-keys -t ${TMUX_SESSION}:0.1 "banner tpcc; sleep 5; /scripts/bin/benchbase-run.sh" Enter
}

tmux_show_ycsb() {
    tmux send-keys -t ${TMUX_SESSION}:0.2 "banner ycsb; sleep 5; /scripts/ycsb.sh" Enter
}

tmux_show_verification() {
    local TMUX_SESSION=${1}

    tmux send-keys -t ${TMUX_SESSION}:5.0 ". /tmp/ini_menu.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:5.0 ". lib/jdbc_cli.sh" Enter
    tmux send-keys -t ${TMUX_SESSION}:5.0 "# cd /scripts; ./arcveri.sh $CFG_DIR" Enter
    tmux send-keys -t ${TMUX_SESSION}:6.0 "vi $VERIFICATOR_HOME/data" Enter 
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

    tmux send-keys -t ${TMUX_SESSION}:2.0 "sleep 5; view ${ARCION_HOME}/data/${LOG_ID}" Enter
    tmux send-keys -t ${TMUX_SESSION}:2.0 ":E" Enter 
}


tmux_show_workload()  {
    local TMUX_SESSION=${1}

    # setup the views to look at log and cfg
    tmux_show_yaml

    # dstat
    tmux send-keys -t ${TMUX_SESSION}:7.0 "dstat | tee $CFG_DIR/dstat.log" Enter 

    # verification
    tmux_show_verification

    # back to the conole
    tmux select-window -t ${TMUX_SESSION}:0.0
}

tmux_show_src_sql_cli() {
    tmux send-keys -t :3.0  "banner src; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_src" enter
    tmux send-keys -t :4.0  "banner src; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_root_cli_src" enter
}

tmux_show_dst_sql_cli() {
    # the dst somtimes cannot get ready to accept connection righ away
    tmux send-keys -t :3.1  "banner dst; sleep 5; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_dst" enter
    tmux send-keys -t :4.1  "banner dst; sleep 5; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_root_cli_dst" enter
}


tmux_show_arcion_cli_tail() {
  local TMUX_SESSION=${1}

  echo $CFG_DIR
  echo tracing the log
  # back to the conole
  tmux select-window -t ${TMUX_SESSION}:0.0
  while [ ! -f $CFG_DIR/arcion.log ]; do
    sleep 1
    echo "waiting for arcion to start"
  done
  tail -f $CFG_DIR/arcion.log &

}
