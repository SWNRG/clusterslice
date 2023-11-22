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

vm_uuid=$($xe vm-import filename=/backup/${template}.xva sr-uuid=${sr_uuid} preserve=false 2>/dev/null)

if [ $? -ne 0 ]; then
  log_output "failure to create VM."
  exit 1
fi
log_output "created VM."

# naming VM
log_output "Naming VM as $vm"
$xe vm-param-set name-label="$vm" uuid="$vm_uuid" >/dev/null 2>/dev/null
if [ $? -ne 0 ]; then
  log_output "Cannot name VM"
  exit 1
fi
log_output "VM named."

echo $vm_uuid
