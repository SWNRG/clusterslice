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
    sleep 3
done
