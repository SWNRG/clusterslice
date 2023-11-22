#!/bin/bash

# script that reverts from a snapshot
# input variables are cloud_name, vm and snapshot_uuid

# check the number of arguments passed
if [ "$#" != "3" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "revert_to_snapshot.sh cloud_server vm_name snapshot_uuid"
  exit 1
fi

# function input variables
server=$1
vm=$2
snapshot_uuid=$3

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

# make sure the VM is powered off
running_status=$(source /root/check_if_vm_is_running.sh $server $vm)
if [[ $running_status == true ]]; then
  log_output "Shutting down VM"
  $VBoxManage controlvm "$vm" poweroff >/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    log_output "Cannot shutdown VM."
  fi
  log_output "VM is down."
fi

# reverting from snapshot
log_output "reverting to snapshot."
$VBoxManage snapshot "$vm" restore $snapshot_uuid >/dev/null 2>/dev/null

if [ $? -ne 0 ]; then
  log_output "cannot revert to snapshot"
  exit 1
fi

# booting node
source /root/boot_vm.sh $server $vm
if [ $? -ne 0 ]; then
  exit 1
fi
