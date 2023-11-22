#!/bin/bash

# import main configuration
source /opt/clusterslice/configuration.sh

# import basic functions
source $main_path/basic_functions.sh

# import input variables
source $main_path/import_input.sh

# import playbook functions
source $main_path/playbook_functions.sh

# import crstatus either from k8s api or status file in shared folder
crstatus=$(get_resource_status $node_name $user_namespace)

if [[ $node_osimage == "none" ]]
then
  echo "Skipping VM deployment and configuration."
else
  if [[ $crstatus == "reserved" ]]; then 
    # create VM and install OS
    create_vm_and_install_os $node_name $node_type $node_ip $node_mac $node_secondaryip $node_secondarymac $node_osimage $cloud_ip $cloud_operator $testbed_namespace      

    if [ $? -ne 0 ]; then
      echo "Cannot create slice"
      change_resource_status $node_name "failed" $testbed_namespace
      exit 1
    else
      # update resource status in kubernetes API
      change_resource_status $node_name "os_ready" $testbed_namespace
      crstatus="os_ready"
    fi
  else
    echo "OS is already installed."
  fi

  if [[ $crstatus == "os_ready" ]]; then

    if [[ $node_type == "masternode" ]] || [[ $node_type == "workernode" ]]; then
      # this is the first ssh connection to the server from the particular container
      # the -o StrictHostKeyChecking=no parameter allows the addition of the 
      # node to the known_hosts, without asking confirmation.
      retcode=$(ssh $node_osaccount@$node_ip -o StrictHostKeyChecking=no "echo 'hello'; echo \$?" 2>/dev/null)
    fi

    # configure server (e.g., set account credentials)
    configure_server $node_name $node_ip $admin_username $admin_password $kubernetes_type
    if [ $? -ne 0 ]; then
      echo "Cannot create slice"
      change_resource_status $node_name "failed" $testbed_namespace
      exit 1
    else
      # update resource status in kubernetes API
      change_resource_status $node_name "os_configured" $testbed_namespace
      crstatus="os_configured"
    fi
  else
    echo "OS is already configured."
  fi
fi

if [[ $kubernetes_type == "none" ]]
then
 echo "Skipping kubernetes deployment and configuration."
 # update resource status in kubernetes API
 change_resource_status $node_name "os_completed" $testbed_namespace
 crstatus="os_completed"
else
 if [[ $crstatus == "os_configured" ]]; then
   # installing kubernetes base, depending on the requested type
   install_kubernetes_base $node_name $kubernetes_type $kubernetes_version $containerd_version $critools_version

   if [ $? -ne 0 ]; then
     echo "Cannot create slice"
     change_resource_status $node_name "failed" $testbed_namespace
     exit 1
   else
     # update resource status in kubernetes API
     change_resource_status $node_name "kubernetes_base" $testbed_namespace
     crstatus="kubernetes_base"
   fi
 else
   echo "Kubernetes base is already installed."
 fi

 if [[ $node_type == "mastervm" ]] || [[ $node_type == "masternode" ]]; then
   if [[ $crstatus == "kubernetes_base" ]]; then
     # installing kubernetes master, depending on the requested type
     # use secondary IP as apiserver, in the case of a private network is present
     if [[ $node_secondaryip == "none" ]] || [[ $node_secondaryip == "" ]]; then
	apiserver=$node_ip
     else
        apiserver=$node_secondaryip 
     fi

     install_kubernetes_master $node_name $admin_username $clusterslice_name $kubernetes_type $kubernetes_networkfabric $kubernetes_networkcidr $kubernetes_servicecidr $testbed_namespace $masters_num $workers_num $apiserver

     if [ $? -ne 0 ]; then
       echo "Cannot create slice"
       change_resource_status $node_name "failed" $testbed_namespace
       exit 1
     else
       # update resource status in kubernetes API
       change_resource_status $node_name "kubernetes_master" $testbed_namespace
       crstatus="kubernetes_master"
     fi
   else 
     echo "Kubernetes master is already installed."
   fi
 fi
fi
