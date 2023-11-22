#!/bin/bash

# copies specific file to all resource managers in particular namespace
# input parameters
filename=$1
user_namespace=$2

# import main configuration
source /opt/clusterslice/configuration.sh

nodes=`kubectl -n $user_namespace get --no-headers=true pods -o name | cut -d/ -f2 | grep resource-manager`

for pod in $nodes
do
  echo "Distributing file $filename to pod $pod"
  kubectl cp $main_path/shared/$filename $user_namespace/$pod:$main_path/shared/$filename
done
