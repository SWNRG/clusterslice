#!/bin/bash

# importing main configuration
source /opt/clusterslice/configuration.sh

# importing basic functions
source /opt/clusterslice/basic_functions.sh

if [ "$#" != "3" ]; then
  # exit script if a parameter is missing
  exit 0
fi

# retrieving clusterslice name
clusterslice_name=$1

# retrieving user namespace
user_namespace=$2

# retrieve input json
input=$3

# keeping track of finished workers and masters
finished_workers=0
finished_masters=0

# measuring total masters and workers in slice
total_workers=`cat /tmp/$clusterslice_name-workers | wc -l`
total_masters=`cat /tmp/$clusterslice_name-masters | wc -l`

rescount=0
for type in `jq -r '.items[].spec.resourcetype' $input`
do
 if [[ $type == "workervm" ]] || [[ $type == "workernode" ]]; then
   name=`jq -r ".items[$rescount].metadata.name" $input`
   status=`jq -r ".items[$rescount].spec.status" $input`
   #echo "checking name $name and status $status"

   # report only workers that exist in slice
   for sliceworker in `cat /tmp/$clusterslice_name-workers`
   do
     if [[ $sliceworker == $name ]]; then
       #echo "worker $name has status $status"
       if [[ $status == "allocated" ]]; then
         let finished_workers=finished_workers+1
       fi
     fi
   done
   
 fi
 if [[ $type == "mastervm" ]] || [[ $type == "masternode" ]]; then
   name=`jq -r ".items[$rescount].metadata.name" $input`  
   status=`jq -r ".items[$rescount].spec.status" $input`

   #echo "checking name $name and status $status"

   # report only masters that exist in slice         
   for slicemaster in `cat /tmp/$clusterslice_name-masters`             
   do                                       
     if [[ $slicemaster == $name ]]; then   
       #echo "master $name has status $status"
       if [[ $status == "allocated" ]]; then
	 let finished_masters=finished_masters+1
       fi
     fi                                      
   done                                      
 fi 
 let rescount=rescount+1
done

echo "finished workers installing applications: $finished_workers of $total_workers"       
echo "finished masters installing applications: $finished_masters of $total_masters"

if [[ $finished_workers -eq $total_workers ]] && [[ $finished_masters -eq $total_masters ]]; then
  echo "slice applications have been deployed"

  # report to kubernetes API (slice object)
  update_slice_status_and_output $clusterslice_name "allocated" "applications deployed" $user_namespace

  # updating all applications as deployed
  echo "marking all applications as deployed"
  mark_slice_apps_deployed $clusterslice_name $user_namespace
fi

