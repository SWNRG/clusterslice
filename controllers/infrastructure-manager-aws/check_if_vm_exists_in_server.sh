#!/bin/bash

# script that checks if vm exists in a particular server
# input variables are server_name and vm 
# it uses the configuration variable host_uuid
# it should return true or false

# check the number of arguments passed
if [ "$#" != "2" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "check_if_vm_exists_in_server.sh cloud_server vm_name"
  exit 1
fi

# function input variables
server=$1
vm=$2

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

log_output "check_if_vm_exists_in_server.sh is not supported from aws IM"

# return bogus running status (VM does not exist)
echo "false"

