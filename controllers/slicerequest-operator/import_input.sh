#!/bin/bash

sliceinput=$1
resourceinput=$2
uidinput=$3

# import uid
uid=`cat $uidinput`

# import clusterslice parameters:
echo "Importing slice input"
input=$sliceinput

clusterslice_name=$(jq -r ".name" $input)
clusterslice_duration=$(jq -r ".duration" $input)
clusterslice_status=$(jq -r ".status" $input)
admin_username=$(jq -r ".credentials.username" $input)
admin_password=$(jq -r ".credentials.password" $input)
deployment_strategy=$(jq -r ".deploymentstrategy" $input)
deployment_domain=$(jq -r ".deploymentdomain" $input)

# check if masters are being set, otherwise lookup parameters from parent field
infrastructure_masters_json=$(jq -r ".infrastructure.masters" $input)
if [[ $infrastructure_masters_json == "" ]] || [[ $infrastructure_masters_json == "null" ]]; then
  infrastructure_masters_type=$(jq -r ".infrastructure.nodes.nodetype" $input)
  infrastructure_masters_count=$(jq -r ".infrastructure.nodes.count" $input)
  if [[ $infrastructure_masters_count == "" ]] || [[ $infrastructure_masters_count == "null" ]]; then
    infrastructure_masters_count=0
  fi
  infrastructure_masters_osimage=$(jq -r ".infrastructure.nodes.osimage" $input)
  infrastructure_masters_osaccount=$(jq -r ".infrastructure.nodes.osaccount" $input)
else
  infrastructure_masters_type=$(jq -r ".infrastructure.masters.mastertype" $input)
  infrastructure_masters_count=$(jq -r ".infrastructure.masters.count" $input)
  if [[ $infrastructure_masters_count == "" ]] || [[ $infrastructure_masters_count == "null" ]]; then
    infrastructure_masters_count=0
  fi
  infrastructure_masters_osimage=$(jq -r ".infrastructure.masters.osimage" $input)
  infrastructure_masters_osaccount=$(jq -r ".infrastructure.masters.osaccount" $input)
fi

infrastructure_workers_type=$(jq -r ".infrastructure.workers.workertype" $input)
infrastructure_workers_count=$(jq -r ".infrastructure.workers.count" $input)
if [[ $infrastructure_workers_count == "" ]] || [[ $infrastructure_workers_count == "null" ]]; then
  infrastructure_workers_count=0
fi
infrastructure_workers_osimage=$(jq -r ".infrastructure.workers.osimage" $input)
infrastructure_workers_osaccount=$(jq -r ".infrastructure.workers.osaccount" $input)

# retrieve kubernetes related configuration
# check if kubernetes field exists
kubernetes_json=$(jq -r ".kubernetes" $input)
if [[ $kubernetes_json == "" ]] || [[ $kubernetes_json == "null" ]]; then
  kubernetes_type="none"
  kubernetes_networkfabric="none"
  kubernetes_networkfabricparameters="none"
  kubernetes_networkcidr="none"
  kubernetes_servicecidr="none"
  kubernetes_version="none"
  containerd_version="none"
  critools_version="none"
else
  kubernetes_type=$(jq -r ".kubernetes.kubernetestype" $input)
  if [[ $kubernetes_type == "" ]] || [[ $kubernetes_type == "null" ]]; then
    kubernetes_type="none"
  fi
  kubernetes_networkfabric=$(jq -r ".kubernetes.networkfabric" $input)
  if [[ $kubernetes_networkfabric == "" ]] || [[ $kubernetes_networkfabric == "null" ]]; then
    kubernetes_networkfabric="none"
  fi
  kubernetes_networkfabricparameters=$(jq -r ".kubernetes.networkfabricparameters" $input)
  if [[ $kubernetes_networkfabricparameters == "" ]] || [[ $kubernetes_networkfabricparameters == "null" ]]; then
    kubernetes_networkfabricparameters="none"
  else
    # replace temporary space character, because it causes issues with bash arrays
    kubernetes_networkfabricparameters="${kubernetes_networkfabricparameters//[ ]/'%'}"
  fi
  kubernetes_networkcidr=$(jq -r ".kubernetes.networkcidr" $input)
  if [[ $kubernetes_networkcidr == "" ]] || [[ $kubernetes_networkcidr == "null" ]]; then
    kubernetes_networkcidr="10.244.0.0/16"
  fi
  kubernetes_servicecidr=$(jq -r ".kubernetes.servicecidr" $input)
  if [[ $kubernetes_servicecidr == "" ]] || [[ $kubernetes_servicecidr == "null" ]]; then
    kubernetes_servicecidr="10.96.0.0/12"
  fi
  kubernetes_version=$(jq -r ".kubernetes.kubernetesversion" $input)
  if [[ $kubernetes_version == "" ]] || [[ $kubernetes_version == "null" ]]; then
    kubernetes_version="none"
  fi
  containerd_version=$(jq -r ".kubernetes.containerdversion" $input)
  if [[ $containerd_version == "" ]] || [[ $containerd_version == "null" ]]; then
    containerd_version="none"
  fi
  critools_version=$(jq -r ".kubernetes.critoolsversion" $input)
  if [[ $critools_version == "" ]] || [[ $critools_version == "null" ]]; then
    critools_version="none"
  fi
fi

# importing resources parameters
echo "Importing resources input"
echo ""
input=$resourceinput
# create empty arrays for masters
masters_hosts=()
masters_types=()
masters_status=()
masters_ips=()
masters_macs=()
masters_secondary_ips=()
masters_secondary_macs=()
masters_domains=()
# workers
workers_hosts=()
workers_types=()
workers_status=()
workers_ips=()
workers_macs=()
workers_secondary_ips=()
workers_secondary_macs=()
workers_domains=()
# cloud servers
cloud_server_ips=()
cloud_server_names=()
cloud_server_operators=()
cloud_server_domains=()
# first cloud server in deployment domain
first_cloud_server_ip=""
first_cloud_server_name=""
first_cloud_server_operator=""
first_cloud_server_domain=""
# testbeds
testbed_ips=()
testbed_names=()
testbed_domains=()
testbed_sites=()
testbed_operators=()
# first testbed in deployment domain
first_testbed_ip=""
first_testbed_name=""
first_testbed_operator=""
first_testbed_domain=""
first_testbed_site=""

# create counter
slrinputcount=0
for name in `jq -r '.items[].metadata.name' $input`
do
   #echo "Importing resource $name"
   resourcetype=$(jq -r ".items[$slrinputcount].spec.resourcetype" $input)
   status=$(jq -r ".items[$slrinputcount].spec.status" $input)
   ip=$(jq -r ".items[$slrinputcount].spec.ip" $input)
   mac=$(jq -r ".items[$slrinputcount].spec.mac" $input)
   if [[ $ip == "" ]]; then
     ip="none"
   fi
   if [[ $mac == "" ]]; then
     mac="none"
   fi
   secondaryip=$(jq -r ".items[$slrinputcount].spec.secondaryip" $input)
   secondarymac=$(jq -r ".items[$slrinputcount].spec.secondarymac" $input)
   if [[ $secondaryip == "" ]]; then
     secondaryip="none"
   fi
   if [[ $secondarymac == "" ]]; then
     secondarymac="none"
   fi
   operator=$(jq -r ".items[$slrinputcount].spec.operator" $input)
   domain=$(jq -r ".items[$slrinputcount].spec.domain" $input)
   site=$(jq -r ".items[$slrinputcount].spec.site" $input)

   # filter out master compute resources in different domains
   if [[ $resourcetype == "mastervm" ]] && [[ $domain == $deployment_domain ]]; then
      masters_hosts+=($name)
      masters_status+=($status)
      masters_types+=($resourcetype)
      masters_ips+=($ip)
      masters_macs+=($mac)
      masters_secondary_ips+=($secondaryip)
      masters_secondary_macs+=($secondarymac)
      masters_domains+=($domain)
   fi

   # filter out worker compute resources in different domains
   if [[ $resourcetype == "workervm" ]] && [[ $domain == $deployment_domain ]]; then
      workers_hosts+=($name)
      workers_status+=($status)
      workers_types+=($resourcetype)
      workers_ips+=($ip)
      workers_macs+=($mac)
      workers_secondary_ips+=($secondaryip)
      workers_secondary_macs+=($secondarymac)
      workers_domains+=($domain)
   fi

   # filter out cloud servers in different domains
   if [[ $resourcetype == "cloudserver" ]] && [[ $domain == $deployment_domain ]]; then
      # keep details of first cloud server
      if [[ -z $first_cloud_server_name ]]; then
        first_cloud_server_ip=$ip
        first_cloud_server_name=$name
	first_cloud_server_operator=$operator
	first_cloud_server_domain=$domain
      fi
      # keep all cloud servers info in arrays besides those in different domains
      cloud_server_ips+=($ip)
      cloud_server_names+=($name)
      cloud_server_operators+=("$operator")
      cloud_server_domains+=($domain)
   fi

   # filter out testbeds in different domains
   if [[ $resourcetype == "testbed" ]] && [[ $domain == $deployment_domain ]]; then
      # keep details of first testbed
      if [[ -z $first_testbed_name ]]; then
	first_testbed_ip=$ip
        first_testbed_name=$name
        first_testbed_operator=$operator
        first_testbed_domain=$domain
        first_testbed_site=$site
      fi
      # keep all testbeds info in arrays
      testbed_ips+=($ip)
      testbed_names+=($name)
      testbed_domains+=($domain)
      testbed_sites+=($site)
      testbed_operators+=($operator)
   fi

   let slrinputcount=slrinputcount+1
done
# importing applications
# create counter
appscount=0
# create empty arrays
app_names=()
app_versions=()
app_parameters=()
app_scopes=()
app_sharedfiles=()
app_waitsforfiles=()
app_deployed=()

input=$sliceinput

# check if applications array is not null
applications_check=$(jq -r '.applications' $input)

if [[ $applications_check != null ]]; then
  for name in `jq -r '.applications[].name' $input`
  do
     appversion=`jq -r ".applications[$appscount].version" $input`
     appparameters=`jq -r ".applications[$appscount].parameters" $input`
     # replace temporary space character, because it causes issues with bash arrays
     appparameters="${appparameters//[ ]/'%'}"    
     appscope=`jq -r ".applications[$appscount].scope" $input`
     appsharefile=`jq -r ".applications[$appscount].sharefile" $input`
     appwaitforfile=`jq -r ".applications[$appscount].waitforfile" $input`
     appdeployed=`jq -r ".applications[$appscount].deployed" $input`

     app_names+=($name)
     app_versions+=($appversion)
     app_parameters+=($appparameters)
     app_sharedfiles+=($appsharefile)
     app_waitsforfiles+=($appwaitforfile)
     app_scopes+=($appscope)
     app_deployed+=($appdeployed)

     let appscount=appscount+1
  done
fi

# convert to none some missing declarations, otherwise the arguments list is becoming messed up
if [[ -z $infrastructure_masters_osimage ]]
then
  infrastructure_masters_osimage="none"
fi

if [[ -z $infrastructure_masters_osaccount ]]
then
  infrastructure_masters_osaccount="user"
fi

if [[ -z $infrastructure_workers_osimage ]]
then
  infrastructure_workers_osimage="none"
fi

if [[ -z $infrastructure_workers_osaccount ]]
then
  infrastructure_workers_osaccount="user"
fi

if [[ -z $kubernetes_type ]]
then
  kubernetes_type="none"
fi

