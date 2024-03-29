#!/bin/bash

# import main configuration
source /opt/clusterslice/configuration.sh

# import basic functions
source $main_path/basic_functions.sh

# import input variables
if $k8s; then
  clusterslice_name=$CLUSTERSLICE_NAME
  user_namespace=$USER_NAMESPACE
else
  clusterslice_name="standalone"
  user_namespace="standalone"
fi
node_name=$NODE_NAME
node_ip=$NODE_IP
node_type=$NODE_TYPE
node_osimage=$NODE_OSIMAGE
node_mac=$NODE_MAC

# define, only if their are not set
if [[ -z $kubernetes_type ]]; then
   kubernetes_type=$KUBERNETES_TYPE
fi
if [[ -z $kubernetes_networkfabric ]]; then
   kubernetes_networkfabric=$KUBERNETES_NETWORKFABRIC
   if [[ -z "$kubernetes_networkfabric" ]] || [[ $kubernetes_networkfabric == "" ]]; then
     kubernetes_networkfabric="none"
   fi
fi

if [[ -z $kubernetes_networkfabric ]]; then
   kubernetes_networkfabricparameters=$KUBERNETES_NETWORKFABRICPARAMETERS
   if [[ -z "$kubernetes_networkfabricparameters" ]] || [[ $kubernetes_networkfabricparameters == "" ]]; then
     kubernetes_networkfabricparameters="none"
   fi
fi

if [[ -z $kubernetes_version ]]; then
   kubernetes_version=$KUBERNETES_VERSION
fi
if [[ -z $containerd_version ]]; then
   containerd_version=$CONTAINERD_VERSION
fi
if [[ -z $critools_version ]]; then
   critools_version=$CRITOOLS_VERSION
fi

admin_username=$ADMIN_USERNAME
admin_password=$ADMIN_PASSWORD

# import playbook functions
source $main_path/playbook_functions.sh

if [[ $node_type == "workervm" ]] || [[ $node_type == "workernode" ]]; then
  # installing kubernetes worker, depending on the requested type
  install_kubernetes_worker $node_name $admin_username $kubernetes_type $kubernetes_networkfabric "$kubernetes_networkfabricparameters"

  if [ $? -ne 0 ]; then
    echo "Cannot create slice"
    exit 1
  else
    echo ""
  fi

  # update resource status in kubernetes API
  change_resource_status $node_name "kubernetes_worker" $testbed_namespace
  #change_resource_status $node_name "kubernetes_worker"
fi
