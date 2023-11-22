FROM flant/shell-operator:latest
ADD slicerequest-operator/slicerequest-hook.sh /hooks
ADD slicerequest-operator/import_input.sh /opt/clusterslice/
ADD slicerequest-operator/import_additional_input.sh /opt/clusterslice/
ADD slicerequest-operator/prepare_slice.sh /opt/clusterslice/
ADD slicerequest-operator/resource_discovery.sh /opt/clusterslice/
ADD slicerequest-operator/resource_reservation.sh /opt/clusterslice/
ADD slicerequest-operator/resource_deployment.sh /opt/clusterslice/
ADD slicerequest-operator/slicerequest-hook-test.sh /opt/clusterslice/
ADD slicerequest-operator/generate_slice.sh /opt/clusterslice/
ADD slicerequest-operator/check_if_slice_is_terminating.sh /opt/clusterslice/
ADD common_scripts/configuration.sh /opt/clusterslice/
ADD common_scripts/basic_functions.sh /opt/clusterslice/
ADD common_scripts/benchmarking.sh /opt/clusterslice/
