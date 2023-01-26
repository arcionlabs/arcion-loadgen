#!/usr/bin/env bash 

WIN=arcion
exists=$( tmux ls | grep "^${WIN}" )
echo $exists
if [ -z "${exists}" ]; then
    # windows
    tmux new-session -s $WIN -d
    tmux new-window -t $WIN:1
    tmux new-window -t $WIN:2
    tmux new-window -t $WIN:3
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
    # work window
    # activate $WIN:0
    tmux select-window -t $WIN:0.0
    tmux select-pane -t $WIN:0.0
fi
tmux attach-session -t $WIN
