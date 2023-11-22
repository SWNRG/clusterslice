#!/bin/bash

# import basic configurations
source /opt/clusterslice/configuration.sh

# import slicerequest name from argument
name=$1
user_namespace=$2

# import basic functions
source /opt/clusterslice/basic_functions.sh

# importing slice and resource details to suitable variables
# we also filter out resources in different deployment domains
source /opt/clusterslice/import_input.sh /tmp/$name-slicerequest.json /tmp/$name-resources.json /tmp/$name-uid

# confirm if slice status is "defined"
if [[ $clusterslice_status != "defined" ]]; then
   echo "Slice status is not \"defined\", aborting operation...."
   exit 1
fi

# implement discovery and allocation of physical nodes, e.g., select appropriate cloud servers to host the resources or allocate test-bed nodes
source /opt/clusterslice/resource_discovery.sh
# returns the following bash arrays
# slice_masters_server_ips
# slice_masters_server_names
# slice_masters_server_operators
# slice_masters_server_sites (for testbed nodes)
# slice_workers_server_ips
# slice_workers_server_names
# slice_workers_server_operators
# slice_workers_server_sites (for testbed nodes)

# deploy testbed (physical) nodes and update computeresources, accordingly.
# execute if testbed nodes are requested
if [[ $infrastructure_masters_type != "vm" ]] || [[ $infrastructure_workers_type != "vm" ]]; then
   # report status to slicerequest (deploying_nodes)
   report_slicerequest_status $clusterslice_name "deploying_nodes" $user_namespace
   # start deployment
   source /opt/clusterslice/resource_deployment.sh
   # import newly added resources
   source /opt/clusterslice/import_additional_input.sh
fi

# implement reservation of resources, e.g., reserve compute resources in particular cloud servers
source /opt/clusterslice/resource_reservation.sh
# returns the following bash arrays (in the case of VM nodes only):
# slice_masters_names
# slice_masters_types
# slice_masters_ips 
# slice_masters_macs
# slice_masters_secondary_ips 
# slice_masters_secondary_macs
# slice_workers_names 
# slice_workers_types
# slice_workers_ips
# slice_workers_macs
# slice_workers_secondary_ips
# slice_workers_secondary_macs

# check if an active slice is currently terminating, before applying the slice
source /opt/clusterslice/check_if_slice_is_terminating.sh

# generates slice object
source /opt/clusterslice/generate_slice.sh > /tmp/$clusterslice_name-clusterslice.yaml

# report status to slicerequest (accepted)
report_slicerequest_status $clusterslice_name "accepted" $user_namespace

# create slice in user namespace
kubectl apply -f /tmp/$clusterslice_name-clusterslice.yaml 
