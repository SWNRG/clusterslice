#!/bin/bash

# script that creates a new virtual machine snapshot
# input variables are cloud_server, vm_uuid and vm_name (it is the same with snapshot_name)

# check the number of arguments passed
if [ "$#" != "3" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "create_snapshot.sh cloud_server vm_uuid and vm_name (it will be the same with snapshot_name)"
  exit 1
fi

# function input variables
server=$1
vm_uuid=$2
vm=$3

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

log_output "check if snapshot already exists."
snapshot_uuid=$(source /root/get_vm_snapshot_uuid.sh $server $vm)

if [[ ! -z $snapshot_uuid ]]; then
  if [[ $force_resource_removal == true ]]; then
    log_output "snapshot already exists, deleting existing snapshot."
    $xe snapshot-uninstall uuid=$snapshot_uuid force=true >/dev/null 2>/dev/null
    if [ $? -ne 0 ]; then
      log_output "cannot remove snapshot."
      exit 1
    fi
    log_output "snapshot removed"
  else
    log_output "snapshot already exists."
    exit 1
  fi
fi

# creating a new snapshot
$xe vm-snapshot vm=$vm_uuid new-name-label="$vm" >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  exit 1
fi
