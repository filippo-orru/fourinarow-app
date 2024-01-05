mkfifo restart_listener_pipe 2>/dev/null
while true; do 
    cat restart_listener_pipe > /dev/null
    echo "Restarting..."
    systemctl restart fourinarow-app
done