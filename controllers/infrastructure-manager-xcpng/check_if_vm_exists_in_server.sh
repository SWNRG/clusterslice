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

if [[ $running_status == false ]]; then
  log_output "booting VM to retrieve its status"
  $xe vm-start vm=$vm >/dev/null 2>/dev/null
  if [ $? -ne 0 ]; then
    log_output "cannot start VM, no worries at this point."
  fi
fi

# check if VM exists in the required server
vm_host_uuid=$($xe vm-list name-label="$vm" params=resident-on --minimal)
if [[ $vm_host_uuid == $host_uuid ]]; then
  log_output "host exists in given server."
  echo "true"
else
  log_output "host does not exist in given server."
  echo "false"
fi
