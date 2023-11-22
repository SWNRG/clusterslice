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

# create and name VM with a single command
$VBoxManage import $image_path/${template}.ova --vsys 0 --vmname $vm 2>/dev/null >/dev/null

if [ $? -ne 0 ]; then
  log_output "failure to create VM."
  exit 1
fi
log_output "created VM."

# retrieve and return VM uuid
source /root/get_vm_uuid.sh $server $vm
