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

log_output "create_snapshot.sh is not supported from aws IM"
