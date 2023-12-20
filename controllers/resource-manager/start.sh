#!/bin/bash

# configure ssh keys
source /opt/clusterslice/configure_ssh.sh

# deploy the resource
source /opt/clusterslice/deploy_resource.sh

# periodically check node status and trigger appropriate tasks, depending on the status
# a scale to zero option could also be used, i.e., die when the deployment is finished. At the time-being,
# the resource-manager represents the resource, so if it is removed, the resource is removed as well.

# do that only in the case of k8s, in the case of dockerized container, the join_worker.sh and deploy_applications.sh scripts should be triggered from outside the container.
if $k8s; then
  crstatus=""
  while true; do
    crstatus=`get_resource_status $node_name $testbed_namespace`
    if [[ $crstatus == "join_worker" ]]; then
       source /opt/clusterslice/join_worker.sh
    fi

    if [[ $crstatus == "wait_for_plugin" ]]; then
       source /opt/clusterslice/wait_for_cluster.sh
       # change resource status to "install_apps"
       change_resource_status $node_name "install_apps" $testbed_namespace
    fi

    if [[ $crstatus == "install_apps" ]]; then
       source /opt/clusterslice/deploy_applications.sh
    fi 
    sleep 5
  done
else
   # in the case of non-k8s deployments
   crstatus=$(get_resource_status $node_name $testbed_namespace)
   if [[ ! $crstatus == "os_completed" ]]; then
      # wait for join command to appear in shared folder
      echo "Wait for join command to appear in the shared folder"
      while [[ ! -f "/opt/clusterslice/shared/$clusterslice_name-kubernetes_join_command" ]]; do
        sleep 5
      done
      # only for worker nodes
      if [[ $node_type == "workervm" ]] || [[ $node_type == "workernode" ]]; then
        #echo "join command appeared in shared folder"
        # copy join command to playbook folder
        cp /opt/clusterslice/shared/$clusterslice_name-kubernetes_join_command $target_playbook_path/kubernetes_join_command
        # join worker node
        source /opt/clusterslice/join_worker.sh
      fi
      # wait for all worker nodes to complete
      echo "wait for all kubernetes worker nodes to complete"
      wait_all_nonk8s_workers_for_status "kubernetes_worker"
      echo "all kubernetes worker nodes are now complete"
      # wait for cluster to complete
      source /opt/clusterslice/wait_for_cluster.sh
   fi
   # now change status to "install_apps" and deploy applications
   change_nonk8s_resource_status "install_apps"
   echo "trigger installing applications"
   source /opt/clusterslice/deploy_applications.sh
fi

