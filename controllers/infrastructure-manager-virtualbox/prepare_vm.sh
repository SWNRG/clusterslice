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

# modifying mac address of first network interface
log_output "modifying mac address of first network interface to $mac"

# stripping : character from mac address
stripped_mac=$(echo "$mac" | sed 's/://g')
$VBoxManage modifyvm $vm --macaddress1 $stripped_mac

if [ $? -ne 0 ]; then
  log_output "cannot modify mac address"
  exit 1
fi
log_output "mac address modified succesfully."
