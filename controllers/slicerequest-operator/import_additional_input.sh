#!/bin/bash

# importing newly added resources (i.e., allocated by test-beds)
echo "Importing the newly added resources"
echo ""

# updating computeresource file
echo "exporting resource details"
resourceinput="/tmp/${kubslice_name}-resources.json"
kubectl get cr -o json > $resourceinput
input=$resourceinput

# create counter
slrinputcount=0
for name in `jq -r '.items[].metadata.name' $input`
do
   resourcetype=$(jq -r ".items[$slrinputcount].spec.resourcetype" $input)
   status=$(jq -r ".items[$slrinputcount].spec.status" $input)
   ip=$(jq -r ".items[$slrinputcount].spec.ip" $input)
   mac=$(jq -r ".items[$slrinputcount].spec.mac" $input)
   secondaryip=$(jq -r ".items[$slrinputcount].spec.secondaryip" $input)
   secondarymac=$(jq -r ".items[$slrinputcount].spec.secondarymac" $input)
   operator=$(jq -r ".items[$slrinputcount].spec.operator" $input)
   domain=$(jq -r ".items[$slrinputcount].spec.domain" $input)
   site=$(jq -r ".items[$slrinputcount].spec.site" $input)

   # filter out master compute resources in different domains
   if [[ $resourcetype == "masternode" ]] && [[ $domain == $deployment_domain ]]; then
      masters_hosts+=($name)
      masters_status+=($status)
      masters_types+=($resourcetype)
      masters_ips+=($ip)
      masters_macs+=($mac)
      masters_secondary_ips+=($secondaryip)
      masters_secondary_macs+=($secondarymac)
      masters_domains+=($domain)
      echo "adding master node $name"
   fi

   # filter out worker compute resources in different domains
   if [[ $resourcetype == "workernode" ]] && [[ $domain == $deployment_domain ]]; then
      workers_hosts+=($name)
      workers_status+=($status)
      workers_types+=($resourcetype)
      workers_ips+=($ip)
      workers_macs+=($mac)
      workers_secondary_ips+=($secondaryip)
      workers_secondary_macs+=($secondarymac)
      workers_domains+=($domain)
      echo "adding worker node $name"
   fi

   let slrinputcount=slrinputcount+1
done
