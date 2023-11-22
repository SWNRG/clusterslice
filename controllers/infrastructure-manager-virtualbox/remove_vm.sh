#!/bin/bash

# script that removes a virtual machine
# input variables are server_name and vm

# check the number of arguments passed
if [ "$#" != "2" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "remove_vm.sh cloud_server vm_name"
  exit 1
fi

# function input variables
server=$1
vm=$2

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

# remove existing VM, only if enforced mode is enabled.
if [[ $force_resource_removal == true ]]; then
  log_output "removing VM ${vm}."
  $VBoxManage unregistervm "$vm" --delete 2>/dev/null >/dev/null

  if [ $? -ne 0 ]; then
    log_output "cannot remove VM."
    exit 1
  fi
  log_output "VM removed."
else
  log_output "cannot remove VM, since force_resource_removal=false"
fi
