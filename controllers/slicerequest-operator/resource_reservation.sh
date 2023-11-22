#!/bin/bash

function check_host_availability () {
   # checks if requested number of hosts is available and returns the first available hosts.
   # input parameters:
   # hostnames (reference to array)
   # resource types (reference to array)
   # status of resources (reference to array)
   # IPs (reference to array)
   # mac addresses (reference to array)
   # secondary IPs (reference to array)
   # secondary mac addresses (reference to array)
   # node domains (reference to array)
   # number of requested hosts 
   # deployment domain

   names=$1[@]
   hostsnames=("${!names}")
   types=$2[@]
   hoststypes=("${!types}")
   status=$3[@]
   hostsstatus=("${!status}")
   ips=$4[@]
   hostsips=("${!ips}")
   macs=$5[@]
   hostsmacs=("${!macs}")
   secondaryips=$6[@]
   hostssecondaryips=("${!secondaryips}")
   secondarymacs=$7[@]
   hostssecondarymacs=("${!secondarymacs}")
   domains=$8[@]
   hostsdomains=("${!domains}")
   hostcount=$9
   deploymentdomain=${10}
    
   echo "searching for $hostcount host(s)"
   rdcount=0
   output=""

   for arrayindex in ${!hostsnames[@]};
   do
     host=${hostsnames[$arrayindex]}
     type=${hoststypes[$arrayindex]}
     status=${hostsstatus[$arrayindex]}
     ip=${hostsips[$arrayindex]}
     mac=${hostsmacs[$arrayindex]}
     secondaryip=${hostssecondaryips[$arrayindex]}
     secondarymac=${hostssecondarymacs[$arrayindex]}
     domain=${hostsdomains[$arrayindex]}

     # reserve free nodes or os_ready test-bed nodes
     if [[ $status == "free" ]] || ([[ $status == "os_ready" ]] && [[ $type == "masternode" ]]) || ([[ $status == "os_ready" ]] && [[ $type == "workernode" ]]); then
       # such nodes should also belong to the requested domain 
       if [[ $deploymentdomain == $domain ]]; then
         let rdcount++
         echo "$host is available. Reserving it ($rdcount node(s) reserved)."

         if [[ -z $output ]] 
         then
            # creating output
            output="{$host,$type,$ip,$mac,$secondaryip,$secondarymac}"
         else
            output="$output,{$host,$type,$ip,$mac,$secondaryip,$secondarymac}"
         fi
     
         if [ $rdcount -eq $hostcount ]
         then
            echo "completed."
            # return 0 (success)
            return 0
         fi
       else
	 echo "$host belongs in a different domain"
       fi
     else
       echo "$host is not available."
     fi
   done
   # return -1 (no success)
   return -1
}

# *******************************************************************
# discovering kubernetes master nodes
# *******************************************************************
echo "*** Discovering kubernetes master nodes ***"
if [ $infrastructure_masters_count -eq 0 ]; then
  echo "No kubernetes master node requested."
else
  # mind that we pass pointers in the case of arrays
  check_host_availability masters_hosts masters_types masters_status masters_ips masters_macs masters_secondary_ips masters_secondary_macs masters_domains $infrastructure_masters_count $deployment_domain
  if [ $? -eq 0 ]
  then
    selected_master_nodes=$output
    echo "Selected kubernetes master nodes: $selected_master_nodes"
  else
    echo "There are no available nodes, swap off an experiment." 
    # report status (failed)
    report_slicerequest_status $clusterslice_name "failed" $user_namespace
    exit 1
  fi
fi
echo ""

# *******************************************************************
# discovering kubernetes worker nodes
# *******************************************************************
echo "*** Discovering kubernetes worker nodes ***"
if [ $infrastructure_workers_count -eq 0 ]; then
  echo "No kubernetes worker node requested."
else
   # skip resource reservation in the case of testbed nodes
   check_host_availability workers_hosts workers_types workers_status workers_ips workers_macs workers_secondary_ips workers_secondary_macs workers_domains $infrastructure_workers_count $deployment_domain
   if [ $? -eq 0 ]; then
     selected_worker_nodes=$output
     echo "Selected kubernetes worker nodes: $selected_worker_nodes"
   else
     echo "There are no available nodes, swap off an experiment." 
     report_slicerequest_status $clusterslice_name "failed" $user_namespace
     exit 1
   fi
fi
echo ""

master_nodes=$(convert_to_suitable_string $selected_master_nodes)
# create empty arrays
slice_masters_names=()
slice_masters_types=()
slice_masters_ips=()
slice_masters_macs=()
slice_masters_secondary_ips=()
slice_masters_secondary_macs=()

for node in $master_nodes;                             
do                                                               
  node_details=$(convert_to_spaced_strings $node)            
  # retreive node name and node IP from spaced strings structure
  node_name=""                                                  
  node_type=""
  node_ip=""
  node_mac=""
  node_secondaryip=""
  node_secondarymac=""
  for str in $node_details; do                                  
    if [[ -z $node_name ]]; then                                                        
      node_name=$str                                            
    else
      if [[ -z $node_type ]]; then
          node_type=$str
      else
        if [[ -z $node_ip ]]; then                                                      
          node_ip=$str                                            
        else
          if [[ -z $node_mac ]]; then		
            node_mac=$str
          else
            if [[ -z $node_secondaryip ]]; then
              node_secondaryip=$str
            else
              node_secondarymac=$str
	    fi
	  fi
        fi		
      fi                                                        
    fi                                                          
  done     
  slice_masters_names+=($node_name) 
  slice_masters_types+=($node_type)
  slice_masters_ips+=($node_ip)
  slice_masters_macs+=($node_mac)
  slice_masters_secondary_ips+=($node_secondaryip)
  slice_masters_secondary_macs+=($node_secondarymac)

  # change node status to "reserved" in the case of VMs
  if [[ $infrastructure_masters_type == "vm" ]]; then
    change_resource_status $node_name "reserved" $testbed_namespace 
  fi
  # updating resource slice and usernamespace fields
  change_resource_slice $node_name $clusterslice_name $testbed_namespace $user_namespace
done

worker_nodes=$(convert_to_suitable_string $selected_worker_nodes)
# create empty arrays
slice_workers_names=()
slice_workers_types=()
slice_workers_ips=()
slice_workers_macs=()
slice_workers_secondary_ips=()
slice_workers_secondary_macs=()

for node in $worker_nodes; 
do 
  node_details=$(convert_to_spaced_strings $node) 
  # retrieve node name and node IP from spaced strings structure 
   node_name=""
  node_type=""
  node_ip=""
  node_mac=""
  node_secondaryip=""
  node_secondarymac=""
  for str in $node_details; do
    if [[ -z $node_name ]]; then
      node_name=$str
    else
      if [[ -z $node_type ]]; then
          node_type=$str
      else
        if [[ -z $node_ip ]]; then
          node_ip=$str
        else
          if [[ -z $node_mac ]]; then
            node_mac=$str
          else
            if [[ -z $node_secondaryip ]]; then
              node_secondaryip=$str
            else
              node_secondarymac=$str
            fi
          fi
        fi
      fi
    fi
  done

  slice_workers_hosts+=($node_name)
  slice_workers_types+=($node_type)
  slice_workers_ips+=($node_ip)
  slice_workers_macs+=($node_mac)
  slice_workers_secondary_ips+=($node_secondaryip)
  slice_workers_secondary_macs+=($node_secondarymac)

  # change node status to "reserved" in the case of VMs
  if [[ $infrastructure_workers_type == "vm" ]]; then
    change_resource_status $node_name "reserved" $testbed_namespace 
  fi
  # updating resource slice field
  change_resource_slice $node_name $clusterslice_name $testbed_namespace $user_namespace
done
