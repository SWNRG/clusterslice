#!/bin/bash

join_command=""

# waiting until secret appears
while [ -z "$join_command" ];
do	
  join_command=`kubectl get secret $clusterslice_name-join-secret -n $testbed_namespace -o jsonpath="{.data.$clusterslice_name-kubernetes_join_command}" | base64 -d`
  sleep 5
done

# create join command file
echo "$join_command" > /tmp/$clusterslice_name-kubernetes_join_command
chmod +x /tmp/$clusterslice_name-kubernetes_join_command
