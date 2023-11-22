#!/bin/bash

# importing configuration
source /opt/clusterslice/configuration.sh

# retreiving slice name, as passed from the hook
name=$1

# and namespace
user_namespace=$2

# import basic function
source /opt/clusterslice/basic_functions.sh

# importing slice details to suitable variables
source /opt/clusterslice/import_input.sh /tmp/$name-slice.json /tmp/$name-uid

# confirm if slice status is "defined"
if [[ $clusterslice_status != "defined" ]]; then
   echo "Slice status is not \"defined\", aborting operation...."
   exit 1
fi

update_slice_status_and_output $clusterslice_name "allocating_infrastructure" "allocating resources" $user_namespace

# copying ssh-secret from swn namespace to the user namespace.
copysecret "ssh-secret" $testbed_namespace $user_namespace

# do the same with registry secret
copysecret "registry-secret" $testbed_namespace $user_namespace

# generate resource deployment pods
source /opt/clusterslice/resources_deployment.sh
