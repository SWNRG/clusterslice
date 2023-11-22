FROM flant/shell-operator:latest
ADD slice-operator/slice-hook.sh /hooks/
ADD slice-operator/computeresource-hook.sh /hooks/
ADD slice-operator/slicerequest-hook.sh /hooks/
ADD slice-operator/import_input.sh /opt/clusterslice/
ADD slice-operator/resources_deployment.sh /opt/clusterslice/
ADD slice-operator/slice-hook-test.sh /opt/clusterslice/
ADD slice-operator/computeresource-hook-test.sh /opt/clusterslice/
ADD slice-operator/deploy_slice.sh /opt/clusterslice/
ADD slice-operator/distribute_join_command.sh /opt/clusterslice/
ADD common_scripts/configuration.sh /opt/clusterslice/
ADD common_scripts/basic_functions.sh /opt/clusterslice/
ADD common_scripts/benchmarking.sh /opt/clusterslice/
ADD slice-operator/check_infrastructure_completion.sh /opt/clusterslice/
ADD slice-operator/check_application_completion.sh /opt/clusterslice/
ADD slice-operator/wait_for_join_command.sh /opt/clusterslice/
