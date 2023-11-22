#!/bin/bash

# script that prepares a virtual machine, i.e., implements custom configuration
# input variables are server_name, vm, mac, secondarymac and vm_uuid
# it uses the configuration variables private_net_uuid and public_net_uuid

# check the number of arguments passed
if [ "$#" != "5" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "prepare_vm.sh cloud_server vm_name mac_address secondary_mac_address vm_uuid"
  exit 1
fi

# function input variables
server=$1
vm=$2
mac=$3
secondarymac=$4
vm_uuid=$5

# import configuration, if it is not imported (standalone execution)
source /root/import_configuration.sh

# removing existing vif for public network
vif_uuid=$($xe vif-list vm-uuid=$vm_uuid network-uuid=$public_net_uuid | head -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)

log_output "Removing vif of VM $vm with uuid $vif_uuid"
temp_vif=$($xe vif-destroy uuid=$vif_uuid)
if [ $? -ne 0 ]; then
  log_output "Cannot remove vif"
  exit 1
fi
log_output "vif removed succesfully."

# removing existing vif for private network (if it exists)
vif_uuid=$($xe vif-list vm-uuid=$vm_uuid network-uuid=$private_net_uuid | head -1 | cut -d ':' -f 2 | cut -d ' ' -f 2)

log_output "Removing vif of VM $vm with uuid $vif_uuid"
temp_vif=$($xe vif-destroy uuid=$vif_uuid)
if [ $? -ne 0 ]; then
  log_output "Cannot remove vif"
  log_output "This is not an issue, probably it does not exist"
else
  log_output "vif removed succesfully."
fi

# adding interfaces, the id=0 is used for primary ip network (used in the cluster) and id=1 for secondary ip 

# adding vif with requested mac address
log_output "Adding vif to VM $vm with mac $mac"
temp_vif=$($xe vif-create device=0 mac=$mac network-uuid=$public_net_uuid vm-uuid=$vm_uuid)
if [ $? -ne 0 ]; then
  log_output "Cannot add vif"
  exit 1
fi
log_output "vif created succesfully."

# create a second interface that can potentially be used for a secondary network
log_output "Adding vif to VM $vm with mac $secondarymac for secondary network"
if [[ $secondarymac != "none" ]] && [[ $secondarymac != "" ]]; then
  # adding vif with requested mac address
  temp_vif=$($xe vif-create device=1 mac=$secondarymac network-uuid=$private_net_uuid vm-uuid=$vm_uuid)
#else
  # do not assign a mac
  #temp_vif=$($xe vif-create device=1 network-uuid=$private_net_uuid vm-uuid=$vm_uuid)
fi 
if [ $? -ne 0 ]; then
  log_output "Cannot add vif"
  exit 1
fi
log_output "vif created succesfully."
