#!/bin/bash

# check if join command exists, otherways wait, i.e., tackle synchronization issues between secret and computeresource monitoring operators

source $main_path/wait_for_join_command.sh

#echo "check if join command exists, otherwise wait"
#while [ ! -f /tmp/kubernetes_join_command ]; do sleep 1; done
#echo "it exists"

for name in `cat /tmp/$clusterslice_name-workers`
do
  pod="resource-manager-$name"
  echo "Distributing keys to worker pod $pod"
  kubectl cp /tmp/$clusterslice_name-kubernetes_join_command $user_namespace/$pod:$main_path/playbooks/kubernetes_join_command

  echo "Executing join cluster command in pod $pod"
  #kubectl -n $user_namespace exec $pod -- $main_path/join_worker.sh 

  # update node status to trigger worker node joining process
  change_resource_status $name "join_worker" $testbed_namespace
  # change_resource_status $name "kubernetes_worker" $testbed_namespace
done

echo "Waiting a few seconds for the applications installation process to be triggered"
