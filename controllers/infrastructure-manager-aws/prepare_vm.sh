#!/bin/bash

# script that prepares a virtual machine, i.e., implements custom configuration
# input variables are server_name, vm, mac, privatemac and vm_uuid

# check the number of arguments passed
if [ "$#" != "5" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "prepare_vm.sh cloud_server vm_name mac_address private_mac_address vm_uuid"
  exit 1
fi

# function input variables
server=$1
vm=$2
mac=$3
privatemac=$4
vm_uuid=$5

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

log_output "prepare_vm.sh is not supported from aws IM"
