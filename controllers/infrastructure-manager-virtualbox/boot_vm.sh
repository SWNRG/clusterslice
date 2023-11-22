#!/bin/bash

# script that boots a virtual machine
# input variables are server_name and vm

# check the number of arguments passed
if [ "$#" != "2" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "boot_vm.sh cloud_server vm_name"
  exit 1
fi

# function input variables
server=$1
vm=$2

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

$VBoxManage startvm "$vm" --type headless >/dev/null 2> /dev/null
if [ $? -ne 0 ]; then
  log_output "Cannot boot node."
  log_output "wait 5 seconds and try one more time."
  sleep 5
  $VBoxManage startvm "$vm" --type headless >/dev/null 2> /dev/null
  if [ $? -ne 0 ]; then
    log_output "Cannot boot node."
    exit 1
  fi
fi
