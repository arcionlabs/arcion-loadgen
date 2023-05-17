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
}

function tmux_show_tpcc() {
    tmux send-keys -t ${TMUX_SESSION}:0.1 "banner tpcc; sleep 5; /scripts/bin/benchbase-run.sh" Enter
}

function tmux_show_ycsb() {
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
tmux_show_log()  {
    local TMUX_SESSION=${1}

    tmux send-keys -t ${TMUX_SESSION}:2.0 "sleep 5; view ${ARCION_HOME}/data/${LOG_ID}" Enter
    tmux send-keys -t ${TMUX_SESSION}:2.0 ":E" Enter 
}