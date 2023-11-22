#!/bin/bash

sliceinput=$1
#resourceinput=$2
uidinput=$2

# import uid
uid=`cat $uidinput`

# import clusterslice parameters:
echo "Importing slice input"
input=$sliceinput

# import generic variables
clusterslice_name=$(jq -r ".name" $input)
clusterslice_duration=$(jq -r ".duration" $input)
clusterslice_status=$(jq -r ".status" $input)
#user_namespace=$(jq -r ".namespace" $input) # already set
admin_username=$(jq -r ".credentials.username" $input)
admin_password=$(jq -r ".credentials.password" $input)

kubernetes_type=$(jq -r ".kubernetes.kubernetestype" $input)
kubernetes_networkfabric=$(jq -r ".kubernetes.networkfabric" $input)
kubernetes_networkcidr=$(jq -r ".kubernetes.networkcidr" $input)
kubernetes_servicecidr=$(jq -r ".kubernetes.servicecidr" $input)
kubernetes_version=$(jq -r ".kubernetes.kubernetesversion" $input)
containerd_version=$(jq -r ".kubernetes.containerdversion" $input)
critools_version=$(jq -r ".kubernetes.critoolsversion" $input)

# importing master and worker nodes
masters_hosts=()
masters_osimages=()
masters_osaccounts=()
masters_types=()
masters_ips=()
masters_macs=()
masters_secondaryips=()
masters_secondarymacs=()
masters_server_ips=()
masters_server_names=()
masters_server_operators=()

workers_hosts=()
workers_osimages=()
workers_osaccounts=()
workers_types=()
workers_ips=()
workers_macs=()
workers_secondaryips=()
workers_secondarymacs=()
workers_server_ips=()
workers_server_names=()
workers_server_operators=()

# create counter
count=0
for name in $(jq -r '.deployment.master[].name' $input)
do
   resourcetype=$(jq -r ".deployment.master[$count].resourcetype" $input)
   osimage=$(jq -r ".deployment.master[$count].osimage" $input)
   osaccount=$(jq -r ".deployment.master[$count].osaccount" $input)
   ip=$(jq -r ".deployment.master[$count].ip" $input)
   mac=$(jq -r ".deployment.master[$count].mac" $input)
   secondaryip=$(jq -r ".deployment.master[$count].secondaryip" $input)
   secondarymac=$(jq -r ".deployment.master[$count].secondarymac" $input)
   serverip=$(jq -r ".deployment.master[$count].serverip" $input)
   servername=$(jq -r ".deployment.master[$count].servername" $input)
   serveroperator=$(jq -r ".deployment.master[$count].serveroperator" $input)

   masters_hosts+=($name)
   masters_osimages+=($osimage)
   masters_osaccounts+=($osaccount)
   masters_types+=($resourcetype)
   masters_ips+=($ip)
   masters_macs+=($mac)
   masters_secondaryips+=($secondaryip)
   masters_secondarymacs+=($secondarymac)
   masters_server_ips+=($serverip)
   masters_server_names+=($servername)
   masters_server_operators+=($serveroperator)

   let count=count+1
done

# reset counter
count=0                                                                       
for name in $(jq -r '.deployment.worker[].name' $input)                    
do                                                                            
   resourcetype=$(jq -r ".deployment.worker[$count].resourcetype" $input) 
   osimage=$(jq -r ".deployment.worker[$count].osimage" $input)
   osaccount=$(jq -r ".deployment.worker[$count].osaccount" $input)
   ip=$(jq -r ".deployment.worker[$count].ip" $input)
   mac=$(jq -r ".deployment.worker[$count].mac" $input)
   secondaryip=$(jq -r ".deployment.worker[$count].secondaryip" $input)
   secondarymac=$(jq -r ".deployment.worker[$count].secondarymac" $input)
   serverip=$(jq -r ".deployment.worker[$count].serverip" $input)
   servername=$(jq -r ".deployment.worker[$count].servername" $input)
   serveroperator=$(jq -r ".deployment.worker[$count].serveroperator" $input)

   workers_hosts+=($name)                                                     
   workers_osimages+=($osimage)                                                
   workers_osaccounts+=($osaccount)
   workers_types+=($resourcetype) 
   workers_ips+=($ip)
   workers_macs+=($mac)   
   workers_secondaryips+=($secondaryip)
   workers_secondarymacs+=($secondarymac)
   workers_server_ips+=($serverip)
   workers_server_names+=($servername)
   workers_server_operators+=($serveroperator) 

   let count=count+1                                                    
done      

# convert to none some missing declarations, otherwise the arguments list is becoming messed up
if [[ -z $kubernetes_type ]]
then
  kubernetes_type="none"
fi

# importing applications
# create counter
count=0
# create empty arrays
app_names=()
app_versions=()
app_parameters=()
app_sharedfiles=()
app_waitsforfiles=()
app_scopes=()
app_deployed=()

input=$sliceinput
apps=`jq -r '.applications' $input`
# do not iterate if application field is null
if [[ $apps != "null" ]]; then
   for name in `jq -r '.applications[].name' $input`
   do
      appversion=`jq -r ".applications[$count].version" $input`
      appparameters=`jq -r ".applications[$count].parameters" $input`
      appsharefile=`jq -r ".applications[$count].sharefile" $input`
      appwaitforfile=`jq -r ".applications[$count].waitforfile" $input`
      appscopes=`jq -r ".applications[$count].scope" $input`
      appdeployed=`jq -r ".applications[$count].deployed" $input`

      # replace temporary space character, because it causes issues with bash arrays
      appparameters="${appparameters//[ ]/'%'}"

      app_names+=($name)
      app_versions+=($appversion)
      app_parameters+=($appparameters)
      app_sharedfiles+=($appsharefile)
      app_waitsforfiles+=($appwaitforfile)
      app_scopes+=($appscopes)
      app_deployed+=($appdeployed)

      let count=count+1
   done
fi
