#!/bin/bash

# import basic configurations
source /opt/clusterslice/configuration.sh

# import slicerequest name from argument
name=$1
user_namespace=$2

# import basic functions
source /opt/clusterslice/basic_functions.sh

# generate and apply slicerequests for all requested clusters
source /opt/clusterslice/apply_slicerequests.sh /tmp/$name-mc-slicerequest.json /tmp/$name-uid

# report status to multiclusterslicerequest (accepted)
report_multiclusterslicerequest_status $clusterslice_name "accepted" $user_namespace
