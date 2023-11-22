#!/bin/bash

# input values
# site_counts
# site_operators
# site_nodetypes
# site_osimages
# clusterslice_name (TBD)

# Printing the site counts
echo "Deploying testbed resources."
request=""
for site in "${!site_counts[@]}"; do
    if [[ $request == "" ]]; then
      operator=${site_operators[$site]}
      request="$site ${site_nodetypes[$site]} ${site_counts[$site]} $infrastructure_masters_count ${site_osimages[$site]}"
    else
      request="$request $site ${site_nodetypes[$site]} ${site_counts[$site]} $infrastructure_masters_count ${site_osimages[$site]}"
    fi
done
kubectl exec $operator -- /root/deploy_testbed_nodes.sh $request
