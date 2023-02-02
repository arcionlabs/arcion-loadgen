#!/usr/bin/env bash 

WIN=${1:-arcion}

exists=$( tmux ls | grep "^${WIN}" )
if [ -z "${exists}" ]; then
    # windows
    tmux new-session -s $WIN -d
    tmux set -g mouse on
    tmux bind-key C-m set-option -g mouse \; display-message 'Mouse #{?mouse,on,off}'
    tmux rename-window -t $WIN.0 console
    tmux new-window -n yaml -t $WIN:1
    tmux new-window -n logs -t $WIN:2
    tmux new-window -n sysbench -t $WIN:3
    tmux new-window -n ycsb -t $WIN:4
    tmux new-window -n validate -t $WIN:5

    # windows 0 to run commands
    tmux split-window -v -t $WIN:0
    tmux split-window -h -t $WIN:0
    tmux send-keys -t $WIN:0.0 "# Enter your commands here" Enter 
    tmux send-keys -t $WIN:0.1 "# /scripts/sysbench.sh" Enter
    tmux send-keys -t $WIN:0.2 "# /scripts/ycsb.sh" Enter
    # windows 1 to view config files
    tmux send-keys -t $WIN:1.0 "cd /tmp; view" Enter 
    tmux send-keys -t $WIN:1.0 ":E" Enter 
    # windows 2 to view logs
    tmux send-keys -t $WIN:2.0 "cd /arcion/data; view" Enter
    tmux send-keys -t $WIN:2.0 ":E" Enter
    # windows 3 
    # windows 4 
    # windows 5
    tmux send-keys -t $WIN:5.0 "# /scripts/validate.sh" Enter
    # activate $WIN:0
    tmux select-window -t $WIN:0.0
    tmux select-pane -t $WIN:0.0
fi
tmux attach-session -t $WIN
