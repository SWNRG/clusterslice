#!/bin/bash
# v3.0 for Kubernetes-based clusterslice testbed
# script works in silent mode

# check the number of arguments passed
if [ "$#" != "5" ]; then
  echo "Illegal number of parameters passed. The correct syntax is:"
  echo "deploy_infrastructure_resource cloud_server vm_name mac_address secondary_mac_address template_name"
  exit 1
fi

# function input variables
server=$1
vm=$2
mac=$3
secondarymac=$4
template=$5

# import configuration
source /root/import_configuration.sh

function deploy_vm () {
  # input variables are vm, mac, secondarymac and template
  # uses also global variable enable_snapshots
  local vm=$1
  local mac=$2
  local secondarymac=$3
  local template=$4

  # create a new VM
  log_output "creating new VM with details $vm and $template."
  vm_uuid=$(source /root/create_vm.sh $server $vm $template)
  if [ $? -ne 0 ]; then
    log_output "cannot create VM."
    exit 1
  fi
  # preparing new VM
  log_output "preparing new VM."
  source /root/prepare_vm.sh $server $vm $mac $secondarymac $vm_uuid
  if [ $? -ne 0 ]; then
    log_output "cannot prepare new VM."
    exit 1
  fi
  # check if snapshots are enabled, in that case, create a snashot.
  if [[ $enable_snapshots == true ]]; then
    # creating snashot
    source /root/create_snapshot.sh $server $vm_uuid $vm
    if [ $? -ne 0 ]; then
      log_output "cannot create snapshot."
      exit 1
    fi
    log_output "snapshot created."
  fi
  # booting node
  log_output "Booting node."
  source /root/boot_vm.sh $server $vm
}

# keep basic debug info
log_output "allocate VM with input parameters: $template $vm $mac $secondarymac"

# we check if VM exists
log_output "checking if VM with the same name already exists"
vm_uuid=$(source /root/get_vm_uuid.sh $server $vm)

if [[ -z $vm_uuid ]]; then
  # VM does not exist
  log_output "VM does not exist, proceeding to deployment of new VM."
  # deploying a new VM
  deploy_vm $vm $mac $secondarymac $template
  if [ $? -ne 0 ]; then
    log_output "cannot deploy VM."
    exit 1
  fi
  log_output "VM deployed successfully."
  exit 0
else
  # VM exists
  log_output "VM exists."
  # if server pooling is enabled, make sure VM exists in the right server
  if [[ $is_pooling_enabled == true ]]; then
    log_output "server pooling is enabled"
    # check if VM exists in the required server
    vm_exists_in_server=$(source /root/check_if_vm_exists_in_server.sh $server $vm)
    if [ $? -ne 0 ]; then
      # cannot check if VM exists in the right server, consider the VM as unusable
      log_output "cannot check if VM exists in the right server, exiting."
      exit 1
    fi
    # produce debug output
    if [[ $vm_exists_in_server == true ]]; then
       # VM exists in the right server
       log_output "VM exists in the right server."
    else
       # VM does not exist in the right server
       log_output "VM does not exist in the right server."
    fi
  else
    # if server pooling is not enabled, then VM exists in the right server
    vm_exists_in_server=true
  fi
  
  # check if snapshots are enabled
  if [[ $enable_snapshots == true ]] && [[ $vm_exists_in_server == true ]]; then
    # check if snapshot exists
    log_output "checking if snapshot exists in VM."
    snapshot_uuid=$(source /root/get_vm_snapshot_uuid.sh $server $vm)
    if [ $? -ne 0 ]; then
      log_output "cannot check if snapshot exists, exiting."
      exit 1
    fi
    if [[ $snapshot_uuid != "" ]]; then
      # snapshot exists, so we revert to snapshot
      log_output "snapshot exists, reverting to snapshot"
      source /root/revert_to_snapshot.sh $server $vm $snapshot_uuid
      if [ $? -ne 0 ]; then
        log_output "cannot revert to snapshot."
        exit 1
      fi
      log_output "reverted to snapshot successfully."
      exit 0
    fi
  fi

  # VM is not usable, remove it or return error level
  if [[ $force_resource_removal == true ]]; then
    log_output "removing existing VM."
    source /root/remove_vm.sh $server $vm
    if [ $? -ne 0 ]; then
      log_output "cannot remove VM, exiting."
      exit 1
    fi
    # deploying a new VM
    deploy_vm $vm $mac $secondarymac $template
    if [ $? -ne 0 ]; then
      log_output "cannot deploy VM."
      exit 1
    fi
    log_output "VM deployed successfully."
  else
    # vm already exists and force_resource_removal=false, exiting
    log_output "vm already exists and force_resource_removal=false, exiting."
    exit 1
  fi
fi
