#!/bin/bash

# iterate through master nodes
# add master nodes
echo "check if selected nodes are currently terminating"
for arrayindex in ${!slice_masters_names[@]};
do
  master_name=${slice_masters_names[$arrayindex]}
  echo "checking master $master_name"
  kubectl wait --for=delete -n $user_namespace pod/resource-manager-$master_name --timeout=300s 2> /dev/null
done

# iterate through worker nodes
for arrayindex in ${!slice_workers_hosts[@]};
do
  worker_name=${slice_workers_hosts[$arrayindex]}
  echo "checking worker $worker_name"
  kubectl wait --for=delete -n $user_namespace pod/resource-manager-$worker_name --timeout=300s 2> /dev/null
done
