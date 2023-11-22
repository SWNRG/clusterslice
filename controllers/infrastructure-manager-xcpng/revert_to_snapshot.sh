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

# reverting from snapshot
log_output "Reverting from snapshot."
$xe snapshot-revert snapshot-uuid=$snapshot_uuid
if [ $? -ne 0 ]; then
  log_output "Cannot revert from snapshot"
  exit 1
fi

# booting node
source /root/boot_vm.sh $server $vm
if [ $? -ne 0 ]; then
  exit 1
fi
