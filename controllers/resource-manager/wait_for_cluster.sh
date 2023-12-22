#!/bin/bash

# import main configuration
source /opt/clusterslice/configuration.sh

# import basic functions
source $main_path/basic_functions.sh

# import input variables
node_name=$NODE_NAME
node_type=$NODE_TYPE

# define only if it is not set
if [[ -z $kubernetes_type ]]; then
   kubernetes_type=$KUBERNETES_TYPE
fi

admin_username=$ADMIN_USERNAME

# import playbook functions
source $main_path/playbook_functions.sh

# wait for cluster only if it is a master node
if [[ $node_type == "mastervm" ]] || [[ $node_type == "masternode" ]]; then
   wait_for_cluster $node_name $admin_username $kubernetes_type
fi
