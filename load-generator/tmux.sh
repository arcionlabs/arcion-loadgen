WIN=arcion
tmux kill-session -t $WIN
# windows
tmux new-session -s $WIN -d
tmux new-window -t $WIN:1
tmux new-window -t $WIN:2
# windows 0 to run commands
tmux split-window -v -t $WIN:0
tmux split-window -h -t $WIN:0
tmux send-keys -t $WIN:0.0 "cd jobs; /jobs/menu.sh" 
tmux send-keys -t $WIN:0.1 "/jobs/sysbench.sh"
tmux send-keys -t $WIN:0.2 "/jobs/ycsb.sh"
# windows 1 to view config files
tmux send-keys -t $WIN:1.0 "cd /tmp; vi" Enter 
tmux send-keys -t $WIN:1.0 ":E" Enter 
# windows 2 to view logs
tmux send-keys -t $WIN:2.0 "cd /arcion/replicant-cli/data; vi" Enter
tmux send-keys -t $WIN:2.0 ":E" Enter
# activate $WIN:0
tmux select-window -t $WIN:0.0
tmux attach-session -t $WIN
