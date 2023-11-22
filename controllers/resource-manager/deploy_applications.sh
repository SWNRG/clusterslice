#!/bin/bash

# import main configuration
source /opt/clusterslice/configuration.sh

# import basic functions
source $main_path/basic_functions.sh

applications=`json_array_items "$APP_NAMES"`

# initialize APPS env variable, to track installed applications
export APPS=""

# get first master for cluster deployments
#first_master_name=`json_array_item "$MASTER_HOSTS" 0`
#first_master_ip=`json_array_item "$MASTER_IPS" 0`

# import playbook functions
source $main_path/playbook_functions.sh

# the cluster deployments should first wait for cluster to be completed, e.g., some network plugins may take some time to complete, such as calico.
#if [[ $first_master_name == $node_name ]]; then
#  source $main_path/wait_for_cluster.sh
#fi

# keep track whether node shared files
#shared_files=false

# update slice status to "allocating_applications"
#update_slice_status_and_output $clusterslice_name "allocating_applications" "allocating applications" $user_namespace

#echo "First master node is $first_master_name with IP $first_master_ip"

# if application variable is empty, write a message
if [[ -z $applications ]]; then
  echo "No applications requested."
fi

appcount=0
for application in $applications;
do
  # deploy application depending on its scope
  # scope levels are: cluster, all, masters, workers
  application_sharefile=`json_array_item "$app_sharedfiles" $appcount`
  application_waitforfile=`json_array_item "$app_waitforfiles" $appcount`
  application_scope=`json_array_item "$app_scopes" $appcount`
  application_parameters=`json_array_item "$app_parameters" $appcount`
  application_version=`json_array_item "$app_versions" $appcount`
  application_deployed=`json_array_item "$app_deployed" $appcount`

  # in the case application shares a file, set shared_files=true
  #if [[ $application_sharefile != "none" ]]; then
  #  shared_files=true
  #fi

  # check if application is already installed
  isinstalled=`check_if_app_is_installed $node_name $application $user_namespace`
  if [[ $isinstalled == false ]]; then
    # escape double quotes in application parameters
    #application_parameters="${application_parameters//[\"]/'\"'}"

    # echo "Evaluating application $application with scope level $application_scope, version $application_version, and parameters $application_parameters"

    if [[ $node_type == "mastervm" ]] || [[ $node_type == "masternode" ]]; then
      if [[ $node_name == $first_master_name ]]; then
        # Node is the first master VM, acceptable apps scoped as: cluster, masters, all
        if [[ ( $application_scope == "cluster" ) || ( $application_scope == "masters" ) || ( $application_scope == "all" ) ]]; then
          echo "Deploying application $application scoped as $application_scope"

          if [[ $application_deployed == "true" ]]; then
            echo "Application $application is already deployed."
          else
            install_application $application $application_version $application_sharefile $application_waitforfile "$application_parameters" $node_name $node_ip $node_type $admin_username $clusterslice_name $user_namespace $kubernetes_type $containerd_version $critools_version
          fi
          if [ $? -ne 0 ]; then
            echo "Cannot install application $application"
            #change_resource_status $node_name "failed" $testbed_namespace
            
          else
            # update resource app field
            change_resource_app $node_name $application $testbed_namespace
            echo ""
          fi
        fi
      else
        # Node is a master VM, acceptable apps scoped as: masters, all
        if [[ ( $application_scope == "masters" ) || ( $application_scope == "all" ) ]]; then
          echo "Deploying application $application"

          if [[ $application_deployed == "true" ]]; then
            echo "Application $application is already deployed."
          else
	    install_application $application $application_version $application_sharefile $application_waitforfile "$application_parameters" $node_name $node_ip $node_type $admin_username $clusterslice_name $user_namespace $kubernetes_type $containerd_version $critools_version
          fi
  
          if [ $? -ne 0 ]; then
            echo "Cannot install application $application"
            #change_resource_status $node_name "failed" $testbed_namespace
            exit 1
          else
            # update resource app field
            change_resource_app $node_name $application $testbed_namespace
            echo ""
          fi
        fi
      fi
    fi

    if [[ $node_type == "workervm" ]] || [[ $node_type == "workernode" ]]; then
      # Node is a worker VM or node, acceptable apps scoped as: workers, all
      if [[ ( $application_scope == "workers" ) || ( $application_scope == "all" ) ]]; then
        echo "Deploying application $application"

        if [[ $application_deployed == "true" ]]; then
          echo "Application $application is already deployed."
        else
          install_application $application $application_version $application_sharefile $application_waitforfile "$application_parameters" $node_name $node_ip $node_type $admin_username $clusterslice_name $user_namespace $kubernetes_type $containerd_version $critools_version
	fi

        if [ $? -ne 0 ]; then
          echo "Cannot install application $application"
          #change_resource_status $node_name "failed" $testbed_namespace
          exit 1
        else
          # update resource app field
          change_resource_app $node_name $application $testbed_namespace
          echo ""
        fi
      fi
    fi

    # update slice application as deployed
    #update_slice_app $clusterslice_name $appcount "deployed" "true" $user_namespace
    #echo "update_slice_app clusterslice_name application deployed true user_namespace"
    #echo "update_slice_app $clusterslice_name $application \"deployed\" \"true\" $user_namespace"
    #echo ""
 else
    echo "Application $application is already deployed."
 fi
 let appcount=appcount+1
done

# update resource status to allocated
change_resource_status $node_name "allocated" $testbed_namespace

