#!/bin/bash

# script that creates a new virtual machine based on a particular template
# input variables are cloud_name, vm, template
# it uses the configuration variable sr_uuid
# it returns vm_uuid

# check the number of arguments passed
if [ "$#" != "3" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "create_vm.sh cloud_server vm_name vm_template"
  exit 1
fi

# function input variables
server=$1
vm=$2
template=$3

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

# reset root fs of particular aws VM
source /root/hostname-$vm-create_vm.sh

if [ $? -ne 0 ]; then
  log_output "failure to reset aws VM."
  exit 1
fi
log_output "resetted aws VM."

log_output "waiting 10 secs"
sleep 10

# return bogus VM uuid
echo "$vm"
