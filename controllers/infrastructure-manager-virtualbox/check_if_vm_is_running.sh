#!/bin/bash

# script that checks if vm is running
# input variables are server_name and vm 
# it should return true (if is running) or false (if it is not running)
# if the VM does not exist, it returns nothing and error code 1

# check the number of arguments passed
if [ "$#" != "2" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "check_if_vm_is_running.sh cloud_server vm_name"
  exit 1
fi

# function input variables
server=$1
vm=$2

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

# Check if the VM is running
running_status=$($VBoxManage showvminfo "$vm" --machinereadable 2>/dev/null | grep -i "VMState=" | cut -d '=' -f2 | tr -d '\"\"')
# it should return either "running" or "poweroff"

case $running_status in
    "running")
        echo "true"
        ;;
    "poweroff")
        echo "false"
        ;;
    *) # cannot determine running status
        log_output "cannot determine running status of VM"
        exit 1
        ;;
esac
