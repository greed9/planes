#!/bin/bash
SESSION_NAME="planes_session"
tmux new -s ${SESSION_NAME} -d
tmux send-keys -t ${SESSION_NAME} 'cd /home/chip/planes' C-m
tmux send-keys -t ${SESSION_NAME} 'dump1090-mutability --net --aggressive' C-m
tmux new-window -t ${SESSION_NAME} 
tmux send-keys -t ${SESSION_NAME}:1 '/usr/sbin/gpsd /dev/ttyS0 -S 3000 -F /var/run/gpsd.sock' C-m
tmux new-window -t ${SESSION_NAME}
tmux send-keys -t ${SESSION_NAME}:2 'cgps :3000' C-m

