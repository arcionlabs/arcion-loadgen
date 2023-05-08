#!/usr/bin/env bash 

# setup SQL screen of source and destination
TMUX_SCREEN=${1:-3}            

# get the host name and type from the menu
if [ -f /tmp/ini_menu.sh ]; then . /tmp/ini_menu.sh; fi
. lib/jdbc_cli.sh

# .0 is source .1 is destination
tmux split-window -d -v -t :${TMUX_SCREEN}
if [ "$?" != "0" ]; then echo "could not split window"; exit 1; fi

# start the CLI
tmux send-keys -t :$TMUX_SCREEN.0  "banner src; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_src" enter
tmux send-keys -t :$TMUX_SCREEN.1  "banner dst; . /tmp/ini_menu.sh; . /scripts/lib/jdbc_cli.sh; jdbc_cli_dst" enter
