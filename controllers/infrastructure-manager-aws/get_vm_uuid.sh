#!/bin/bash

# script that gets the uuid from a VM
# input variables are server_name and vm
# returns empty variable, if VM does not exist

# check the number of arguments passed
if [ "$#" != "2" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "get_vm_uuid.sh cloud_server vm_name"
  exit 1
fi

# function input variables
server=$1
vm=$2

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

log_output "get_vm_uuid.sh is not supported from aws IM"

# return bogus vm uuid
echo ""
