#!/usr/bin/env bash

# arguments passed arcdemo.sh
ARGS=( "${@}" )
ARGS_LEN=${#ARGS[@]}

# expected env vars
export ARCDEMO_OPTS="${ARGS[@]:0:$((ARGS_LEN-3))}" 
export REPL_TYPE="${ARGS[$((ARGS_LEN-3))]}"
export SOURCE="${ARGS[$((ARGS_LEN-2))]}"
export TARGET="${ARGS[$((ARGS_LEN-1))]}"
export FILENAME=${REPL_TYPE}_${SOURCE}_${TARGET}
export RECFILE=/tmp/${FILENAME}.asciicast

# clear screen
tmux send-keys -t arcion:0.3  C-c
tmux send-keys -t arcion:0.3 'clear' Enter

tmux send-keys -t arcion:0.2  C-c
tmux send-keys -t arcion:0.2 'clear' Enter

tmux send-keys -t arcion:0.1  C-c
tmux send-keys -t arcion:0.1 'clear' Enter

tmux send-keys -t arcion:0.0  C-c
tmux send-keys -t arcion:0.0 'clear' Enter

tmux select-pane -t arcion:0.0

# generate asciinema
recdemo.expect "${@}"

# move asciinema into the artifact dir
. /tmp/ini_menu.sh
mv $RECFILE $CFG_DIR/.

# create gif
~/.cargo/bin/agg --idle-time-limit .5 $CFG_DIR/$FILENAME.asciicast $CFG_DIR/$FILENAME.gif

