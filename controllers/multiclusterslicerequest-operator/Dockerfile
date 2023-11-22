FROM flant/shell-operator:latest
ADD multiclusterslicerequest-operator/multiclusterslicerequest-hook.sh /hooks
ADD multiclusterslicerequest-operator/apply_slicerequests.sh /opt/clusterslice/
ADD multiclusterslicerequest-operator/prepare_slicerequests.sh /opt/clusterslice/
ADD multiclusterslicerequest-operator/multiclusterslicerequest-hook-test.sh /opt/clusterslice/
ADD multiclusterslicerequest-operator/generate_slicerequest.sh /opt/clusterslice/
ADD common_scripts/configuration.sh /opt/clusterslice/
ADD common_scripts/basic_functions.sh /opt/clusterslice/
ADD common_scripts/benchmarking.sh /opt/clusterslice/
