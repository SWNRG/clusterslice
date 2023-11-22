#!/bin/bash

# importing main configuration
source /opt/clusterslice/configuration.sh

# importing basic functions
source /opt/clusterslice/basic_functions.sh

if [ "$#" != "4" ]; then
  # exit script if a parameter is missing
  exit 0
fi

# retrieving clusterslice name
clusterslice_name=$1

# retrieving user namespace
user_namespace=$2

# retrieve input json
input=$3

# triggering status
triggering_status=$4

# keeping track of finished workers with kubernetes base (finished_workers_base), finished workers that joined cluster or without a requirement to join cluster (finished_workers) and master nodes (cluster created or no requirement to create cluster)
finished_workers_base=0
rm /tmp/$clusterslice_name-finished_workers_base 2> /dev/null
finished_workers=0
rm /tmp/$clusterslice_name-finished_workers 2> /dev/null
finished_masters=0
rm /tmp/$clusterslice_name-finished_masters 2> /dev/null

# measuring total workers and masters in slice
total_workers=`cat /tmp/$clusterslice_name-workers | wc -l`
total_masters=`cat /tmp/$clusterslice_name-masters | wc -l`

rescount=0
for type in `jq -r '.items[].spec.resourcetype' $input`
do
 if [[ $type == "workervm" ]] || [[ $type == "workernode" ]]; then
   name=`jq -r ".items[$rescount].metadata.name" $input`
   status=`jq -r ".items[$rescount].spec.status" $input`

   # report only workers that exist in slice
   for sliceworker in `cat /tmp/$clusterslice_name-workers`
   do
     if [[ $sliceworker == $name ]]; then
       if [[ $status == "kubernetes_base" ]]; then
         echo $name >> /tmp/$clusterslice_name-finished_workers_base
         let finished_workers_base=finished_workers_base+1
       else
         if [[ $status == "kubernetes_worker" ]] || [[ $status == "allocated" ]] || [[ $status == "os_completed" ]]; then
           echo $name >> /tmp/$clusterslice_name-finished_workers
           let finished_workers=finished_workers+1
         fi
       fi
     fi
   done
   
 fi
 if [[ $type == "mastervm" ]] || [[ $type == "masternode" ]]; then
   name=`jq -r ".items[$rescount].metadata.name" $input`  
   status=`jq -r ".items[$rescount].spec.status" $input`

   # report only masters that exist in slice         
   for slicemaster in `cat /tmp/$clusterslice_name-masters`             
   do                                       
     if [[ $slicemaster == $name ]]; then   
       #echo "master $name has status $status"
       if [[ $status == "kubernetes_master" ]] || [[ $status == "allocated" ]] || [[ $status == "os_completed" ]]; then
         echo $name >> /tmp/$clusterslice_name-finished_masters
	 let finished_masters=finished_masters+1
       fi
     fi                                      
   done                                      
 fi 
 let rescount=rescount+1
done

echo "workers with kubernetes base are $finished_workers of $total_workers"
echo "finished workers are $finished_workers of $total_workers"       
echo "finished masters are $finished_masters of $total_masters"

# update slice with finished nodes status
update_slice_master_nodes $clusterslice_name "$finished_masters/$total_masters" $user_namespace
update_slice_worker_nodes $clusterslice_name "$finished_workers/$total_workers" $user_namespace

# execute only if a number of workers is being set
if [[ $total_workers -gt 0 ]]; then
  if [[ $finished_workers_base -eq $total_workers ]] && [[ $finished_masters -eq $total_masters ]]; then
    echo "workers are ready to receive join commands"

    #if [[ $triggering_status != "os_completed" ]]; then
    echo "distributing join commands"
    source $main_path/distribute_join_command.sh
    #fi
  fi
fi

if [[ $finished_workers -eq $total_workers ]] && [[ $finished_masters -eq $total_masters ]]; then
  echo "slice is almost completed"

  # report to kubernetes API (slice object)
  update_slice_status_and_output $clusterslice_name "infrastructure_completed" "infrastructure deployed" $user_namespace

  echo "Infrastructure is completed, wait for nodes to become ready"
  echo ""
  echo "Nodes are being triggered in a few seconds to install requested applications"
  update_slice_status_and_output $clusterslice_name "allocating_applications" "allocating applications" $user_namespace

  echo "setting nodes' status to install_apps, besides master node that should wait for network plugin to complete"
  for slicemaster in `cat /tmp/$clusterslice_name-masters`
  do
    # update only if app installation is not finished already, i.e., in the case no applications are being requested
    current_status=`get_resource_status $slicemaster $testbed_namespace`
    if [[ $current_status == "os_completed" ]]; then
       change_resource_status $slicemaster "install_apps" $testbed_namespace
    else
       if [[ $current_status != "allocated" ]]; then
         change_resource_status $slicemaster "wait_for_plugin" $testbed_namespace
       fi
    fi
  done 
  for sliceworker in `cat /tmp/$clusterslice_name-workers`
  do
    # update only if app installation is not finished already, i.e., in the case no applications are being requested
    current_status=`get_resource_status $sliceworker $testbed_namespace`
    if [[ $current_status != "allocated" ]]; then
       change_resource_status $sliceworker "install_apps" $testbed_namespace
    fi
  done
fi
