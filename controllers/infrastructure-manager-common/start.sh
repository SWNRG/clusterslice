#!/bin/bash

# Function to clean up and gracefully exit
cleanup() {
    echo "The Infrastructure Manager received a termination signal."
    exit 0
}

# Trap termination signals and call the cleanup function
trap 'cleanup' SIGTERM SIGINT

# configure ssh keys
source /root/configure_ssh.sh

# implement endless loop
while true; do
    # terminate in the case of "completed" file appears in /root/, this means the non-k8s deployment is completed
    if [ -f "/root/completed" ]; then
      echo "Triggered termination signal"
      exit 0
    fi
    sleep 3
done
