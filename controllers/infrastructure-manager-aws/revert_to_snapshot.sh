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

log_output "revert_to_snapshot.sh is not supported from aws IM"
