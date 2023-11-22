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

# check if VM is running
# VM should be started, otherwise we cannot view the resident-on param
running_status=$(source /root/check_if_vm_is_running.sh $server $vm)
if [ $? -ne 0 ]; then
  log_output "VM does not exist, exiting."
  exit 1
fi

# server pooling is not supported, so return running status
echo $running_status

