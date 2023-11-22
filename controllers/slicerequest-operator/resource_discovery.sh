#!/bin/bash

# input is: 
# 1) deployment_strategy, with options "", firstone, balanced, roundrobin
# 2) the deployment_domain
# 3) the cluster node requirements:
# infrastructure_masters_type (vm or other representing the node type in the case of testbed)
# infrastructure_workers_type (vm or other representing the node type in the case of testbed)
# infrastructure_masters_count (requested number)
# infrastructure_workers_count (requested number)
# infrastructure_masters_osimage (name of VM or testbed image)
# infrastructure_workers_osimage (name of VM or testbed image)
# 4) the details of cloud servers and testbed infrastructures:
# cloud_server_ips (array)
# cloud_server_names (array)
# cloud_server_operators (array)
# first_cloud_server_ip (string)
# first_cloud_server_name (string)
# first_cloud_server_operator (string)
# testbed_ips (array)
# testbed_names (array)
# testbed_sites (array)
# testbed_operators (array)
# first_testbed_ip (string)
# first_testbed_name (string)
# first_testbed_operator (string)
# first_testbed_site (string)

# output is (the IPs of selected servers per master and worker node):
# slice_masters_server_ips
# slice_masters_server_names
# slice_masters_server_operators
# slice_masters_server_sites (for testbed deployments)
# slice_workers_server_ips
# slice_workers_server_names
# slice_workers_server_operators
# slice_workers_server_sites (for testbed deployments)

# more sophisticated resource discovery & embedding algorithms are in our plans.

# calculate number of master and worker nodes, as well as the number of cloud servers and testbeds
num_masters=$infrastructure_masters_count                              
num_workers=$infrastructure_workers_count
total_nodes=$((num_masters + num_workers))
num_cloud_servers=${#cloud_server_ips[@]}
num_testbeds=${#testbed_names[@]}

# default deployment_strategy is "firstone"
if [[ "$deployment_strategy" == "firstone" ]] || [[ "$deployment_strategy" == "" ]]; then
  # assign first cloud server or testbed to all nodes
  for ((i = 0; i < num_masters; i++)); do
    if [[ $infrastructure_masters_type == "vm" ]]; then
      # cloud deployment
      slice_masters_server_ips+=("$first_cloud_server_ip")
      slice_masters_server_names+=("$first_cloud_server_name")
      slice_masters_server_operators+=("$first_cloud_server_operator")
    else
      # testbed deployment
      slice_masters_server_ips+=("$first_testbed_ip")
      slice_masters_server_names+=("$first_testbed_name")
      slice_masters_server_operators+=("$first_testbed_operator")
      slice_masters_server_sites+=("$first_testbed_site")
    fi
  done
  for ((i = 0; i < num_workers; i++)); do
    if [[ $infrastructure_workers_type == "vm" ]]; then
      # cloud deployment
      slice_workers_server_ips+=("$first_cloud_server_ip")
      slice_workers_server_names+=("$first_cloud_server_name")
      slice_workers_server_operators+=("$first_cloud_server_operator")
    else
      # testbed deployment
      slice_workers_server_ips+=("$first_testbed_ip")
      slice_workers_server_names+=("$first_testbed_name")
      slice_workers_server_operators+=("$first_testbed_operator")
      slice_workers_server_sites+=("$first_testbed_site")
    fi
  done
elif [[ "$deployment_strategy" == "balanced" ]]; then
  # balanced cloud based deployment for master nodes
  if [[ $infrastructure_masters_type == "vm" ]]; then
    # assign a balanced number of VMs among the servers
    # calculate the number of master VMs per server
    master_vms_per_server=$((num_masters / num_cloud_servers))
    # calculate the remaining master VMs that need to be distributed
    remaining_master_vms=$((num_masters % num_cloud_servers))

    # array to store the number of master VMs for each server
    server_master_vms=()

    # distribute the master VMs
    for ((i=0; i<num_cloud_servers; i++))
    do
      # add the base number of master VMs per server
      server_master_vms[$i]=$master_vms_per_server

      # distribute the remaining master VMs one by one
      if [ $remaining_master_vms -gt 0 ]; then
        server_master_vms[$i]=$((server_master_vms[$i] + 1))
        remaining_master_vms=$((remaining_master_vms - 1))
      fi
      #echo "Server $((i+1)): ${server_master_vms[$i]} master VMs"
      # assigning server ip to particular VMs
      for ((k=0; k<${server_master_vms[$i]}; k++))
      do
        slice_masters_server_ips+=("${cloud_server_ips[$i]}")
        slice_masters_server_names+=("${cloud_server_names[$i]}")
        slice_masters_server_operators+=("${cloud_server_operators[$i]}")
      done
    done
  else
    # assign a balanced number of nodes among the testbeds
    # calculate the number of master nodes per testbed
    master_nodes_per_testbed=$((num_masters / num_testbeds))
    # calculate the remaining master nodes that need to be distributed
    remaining_master_nodes=$((num_masters % num_testbeds))

    # array to store the number of master nodes for each testbed
    server_master_nodes=()

    # distribute the master nodes
    for ((i=0; i<num_testbeds; i++))
    do
      # add the base number of master nodes per testbed
      server_master_nodes[$i]=$master_nodes_per_testbed

      # distribute the remaining master nodes one by one
      if [ $remaining_master_nodes -gt 0 ]; then
        server_master_nodes[$i]=$((server_master_nodes[$i] + 1))
        remaining_master_nodes=$((remaining_master_nodes - 1))
      fi
      # assigning testbed details to particular nodes
      for ((k=0; k<${server_master_nodes[$i]}; k++))
      do
        slice_masters_server_ips+=("${testbed_ips[$i]}")
        slice_masters_server_names+=("${testbed_names[$i]}")
        slice_masters_server_operators+=("${testbed_operators[$i]}")
	slice_masters_server_sites+=("${testbed_sites[$i]}")
      done
    done
  fi

  # balanced cloud based deployment for worker nodes
  if [[ $infrastructure_workers_type == "vm" ]]; then
    # assign a balanced number of VMs among the servers
    # calculate the number of worker VMs per server
    worker_vms_per_server=$((num_workers / num_cloud_servers))
    # calculate the remaining worker VMs that need to be distributed
    remaining_worker_vms=$((num_workers % num_cloud_servers))

    # array to store the number of worker VMs for each server
    server_worker_vms=()

    # distribute the worker VMs
    for ((i=0; i<num_cloud_servers; i++))
    do
      # add the base number of VMs per server
      server_worker_vms[$i]=$worker_vms_per_server
    
      # distribute the remaining worker VMs one by one
      if [ $remaining_worker_vms -gt 0 ]; then
        server_worker_vms[$i]=$((server_worker_vms[$i] + 1))
        remaining_worker_vms=$((remaining_worker_vms - 1))
      fi
      #echo "Server $((i+1)): ${server_worker_vms[$i]} worker VMs"
      # assigning server ip to particular VMs                                     
      for ((k=0; k<${server_worker_vms[$i]}; k++))                                
      do                                                                          
        slice_workers_server_ips+=("${cloud_server_ips[$i]}")
        slice_workers_server_names+=("${cloud_server_names[$i]}")      
        slice_workers_server_operators+=("${cloud_server_operators[$i]}")
      done
    done
  else
    # balanced testbed based deployment for worker nodes
    # assign a balanced number of nodes among the testbeds
    # calculate the number of worker nodes per testbed
    worker_nodes_per_testbed=$((num_workers / num_testbeds))
    # calculate the remaining worker nodes that need to be distributed
    remaining_worker_nodes=$((num_workers % num_testbeds))

    # array to store the number of worker nodes for each server
    server_worker_nodes=()

    # distribute the worker nodes
    for ((i=0; i<num_testbeds; i++))
    do
      # add the base number of nodes per tetbed
      server_worker_nodes[$i]=$worker_nodes_per_testbed

      # distribute the remaining worker nodes one by one
      if [ $remaining_worker_nodes -gt 0 ]; then
        server_worker_nodes[$i]=$((server_worker_nodes[$i] + 1))
        remaining_worker_nodes=$((remaining_worker_nodes - 1))
      fi
      for ((k=0; k<${server_worker_nodes[$i]}; k++))
      do
        slice_workers_server_ips+=("${testbed_ips[$i]}")
        slice_workers_server_names+=("${testbed_names[$i]}")
        slice_workers_server_operators+=("${testbed_operators[$i]}")
	slice_workers_server_sites+=("${testbed_sites[$i]}")
      done
    done
  fi
fi

# Print the selected servers or testbeds for masters

# Also count the number of required nodes per testbed site
# Declare an associative array to store the counts of different sites
declare -A site_counts
declare -A site_operators
declare -A site_nodetypes
declare -A site_osimages

if [[ $infrastructure_masters_type == "vm" ]]; then
  echo "Selected servers for masters:"
  for server_ip in "${slice_masters_server_ips[@]}"; do
    echo "$server_ip"
  done
else
  echo "Selected testbeds for masters:"
  testbed_count=0
  for testbed_name in "${slice_masters_server_names[@]}"; do
    testbed_site=${slice_masters_server_sites[$testbed_count]}
    testbed_operator=${slice_masters_server_operators[$testbed_count]}
    echo "$testbed_name at $testbed_site"

    # Check if the site exists in the associative array and increment its count
    if [[ ${site_counts[$testbed_site]+_} ]]; then
        ((site_counts[$testbed_site]++))
    else
        # If the site doesn't exist, initialize the count to 1
        site_counts[$testbed_site]=1
	# keep also operator
        site_operators[$testbed_site]=$testbed_operator
	site_nodetypes[$testbed_site]=$infrastructure_masters_type
        site_osimages[$testbed_site]=$infrastructure_masters_osimage
    fi

    let testbed_count=testbed_count+1
  done
fi

# Print the selected servers or testbeds for workers
if [[ $infrastructure_workers_type == "vm" ]]; then
  echo "Selected servers for workers:"
  for server_ip in "${slice_workers_server_ips[@]}"; do
    echo "$server_ip"
  done
else
  echo "Selected testbeds for workers:"
  testbed_count=0
  for testbed_name in "${slice_workers_server_names[@]}"; do
    testbed_site=${slice_workers_server_sites[$testbed_count]}
    testbed_operator=${slice_workers_server_operators[$testbed_count]}
    echo "$testbed_name at $testbed_site"
        # Check if the site exists in the associative array and increment its count
    if [[ ${site_counts[$testbed_site]+_} ]]; then
        ((site_counts[$testbed_site]++))
    else
        # If the site doesn't exist, initialize the count to 1
        site_counts[$testbed_site]=1
	# keep also operator
        site_operators[$testbed_site]=$testbed_operator
	site_nodetypes[$testbed_site]=$infrastructure_workers_type
	site_osimages[$testbed_site]=$infrastructure_workers_osimage
    fi
    let testbed_count=testbed_count+1
  done
fi
