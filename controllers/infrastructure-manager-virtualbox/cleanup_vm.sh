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

if [[ $enable_snapshots == true ]]; then
  log_output "Do not remove VM, since snapshot mode is enabled."
  running_status=$(source /root/check_if_vm_is_running.sh $server $vm)
  if [[ $running_status == true ]]; then
    log_output "Shutting down VM"
    $VBoxManage controlvm "$vm" poweroff
    if [ $? -ne 0 ]; then
      log_output "Cannot shutdown VM."
    fi
    log_output "VM is down."
  fi
  exit 0
else
  # remove existing VM, only if enforced mode is enabled.
  if [[ $force_resource_removal == true ]]; then
    log_output "Removing VM ${vm}."
    $VBoxManage unregistervm "$vm" --delete

    if [ $? -ne 0 ]; then
      log_output "Cannot remove VM."
      exit 1
    fi
    log_output "VM removed."
  else
    log_output "Do not remove VM, since force_resource_removal=false"
  fi
fi
