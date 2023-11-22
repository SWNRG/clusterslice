#!/bin/bash

# Check if the host IP is provided as an argument
if [ -z "$1" ]; then
    echo "Error: Host IP not provided. Please provide the host IP as the first argument."
    exit 1
fi

# Define the host IP variable
host_ip="$1"  # Change this to your desired host IP

# File containing master IPs
masters_file="/opt/clusterslice/info/masters"

# File containing worker IPs
workers_file="/opt/clusterslice/info/workers"

# keep track of all IPs
all_ips=()

# iterate through all vxlans
current_vxlan=1

# extract master nodes with different IP
while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $1}')

    all_ips+=($ip) 
done < "$masters_file"

# extract worker nodes with different IP
while IFS= read -r line; do
    ip=$(echo "$line" | awk '{print $1}')

    #if [ "$ip" != "$hostip" ]; then
    all_ips+=($ip)
done < "$workers_file"

# Print all ip combinations

ip_combinations=()
for source_ip in "${all_ips[@]}"; do
   for destination_ip in "${all_ips[@]}"; do
     # show combinations not already tracked
     if [[ "$source_ip" != "$destination_ip" ]] && [[ ! "${ip_combinations[@]} " =~ "${source_ip}-${destination_ip}" ]]; then	   
        #echo "$source_ip -> $destination_ip vxlan${current_vxlan}"
	# keep track particular combinations
	ip_combinations+=("${source_ip}-${destination_ip}")
	ip_combinations+=("${destination_ip}-${source_ip}")
	# keep vxlans host_ip takes part
	if [[ "${source_ip}" == "${host_ip}" ]]; then
	   echo "vxlan${current_vxlan}: \"${destination_ip}\""
        elif [[ "${destination_ip}" == "${host_ip}" ]]; then
           echo "vxlan${current_vxlan}: \"${source_ip}\""
	else
	   # print empty vxlan
	   echo "vxlan${current_vxlan}: \"\""
	fi 
        let current_vxlan=current_vxlan+1	
     fi
   done
done

# print the rest of vxlans
while [[ $current_vxlan -le 10 ]]; do
    # print empty vxlan
    echo "vxlan${current_vxlan}: \"\""
    let current_vxlan=current_vxlan+1
done
