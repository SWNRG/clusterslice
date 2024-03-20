#!/bin/bash

sliceinput=$1
uidinput=$2

# import uid
uid=`cat $uidinput`

# import clusterslice parameters:
echo "Importing multi-cluster slice request input"
input=$sliceinput

clusterslice_name=`jq -r ".name" $input`
clusterslice_duration=`jq -r ".duration" $input`
clusterslice_status=`jq -r ".status" $input`
admin_username=`jq -r ".credentials.username" $input`
admin_password=`jq -r ".credentials.password" $input`
deployment_strategy=$(jq -r ".deploymentstrategy" $input)

# confirm if slice status is "defined"
if [[ $clusterslice_status != "defined" ]]; then
   echo "Slice status is not \"defined\", aborting operation...."
   exit 1
fi

# iterate through all clusters
clustercount=0
for clustername in `jq -r '.clusters[].name' $input`
do
  echo "requesting cluster with name $clustername"

  # retrieve clusterdomain
  clusterdomain=$(jq -r ".clusters[$clustercount].deploymentdomain" $input)

  #infrastructure_masters_mastertype=$(jq -r ".clusters[$clustercount].infrastructure.masters.mastertype" $input)
  #infrastructure_masters_count=$(jq -r ".clusters[$clustercount].infrastructure.masters.count" $input)
  #infrastructure_masters_os=$(jq -r ".clusters[$clustercount].infrastructure.masters.osimage" $input)
  #infrastructure_masters_osaccount=$(jq -r ".clusters[$clustercount].infrastructure.masters.osaccount" $input)

  # check if masters are being set, otherwise lookup parameters from parent field
  infrastructure_masters_json=$(jq -r ".clusters[$clustercount].infrastructure.masters" $input)
  if [[ $infrastructure_masters_json == "" ]] || [[ $infrastructure_masters_json == "null" ]]; then
     infrastructure_masters_mastertype=$(jq -r ".clusters[$clustercount].infrastructure.nodes.nodetype" $input)
     infrastructure_masters_count=$(jq -r ".clusters[$clustercount].infrastructure.nodes.count" $input)
     if [[ $infrastructure_masters_count == "" ]] || [[ $infrastructure_masters_count == "null" ]]; then
       infrastructure_masters_count=0
     fi
     infrastructure_masters_os=$(jq -r ".clusters[$clustercount].infrastructure.nodes.osimage" $input)
     infrastructure_masters_osaccount=$(jq -r ".clusters[$clustercount].infrastructure.nodes.osaccount" $input)
  else
     infrastructure_masters_mastertype=$(jq -r ".clusters[$clustercount].infrastructure.masters.mastertype" $input)
     infrastructure_masters_count=$(jq -r ".clusters[$clustercount].infrastructure.masters.count" $input)
     if [[ $infrastructure_masters_count == "" ]] || [[ $infrastructure_masters_count == "null" ]]; then
        infrastructure_masters_count=0
     fi
     infrastructure_masters_os=$(jq -r ".clusters[$clustercount].infrastructure.masters.osimage" $input)
     infrastructure_masters_osaccount=$(jq -r ".clusters[$clustercount].infrastructure.masters.osaccount" $input)
  fi

  infrastructure_workers_json=$(jq -r ".clusters[$clustercount].infrastructure.workers" $input)
  if [[ $infrastructure_workers_json != "" ]] && [[ $infrastructure_workers_json != "null" ]]; then
    infrastructure_workers_workertype=$(jq -r ".clusters[$clustercount].infrastructure.workers.workertype" $input)
    infrastructure_workers_count=$(jq -r ".clusters[$clustercount].infrastructure.workers.count" $input)
    infrastructure_workers_os=$(jq -r ".clusters[$clustercount].infrastructure.workers.osimage" $input)
    infrastructure_workers_osaccount=$(jq -r ".clusters[$clustercount].infrastructure.workers.osaccount" $input)
  else
    infrastructure_workers_workertype=""
    infrastructure_workers_count=""
    infrastructure_workers_os=""
    infrastructure_workers_osaccount=""
  fi

  kubernetes_type=$(jq -r ".clusters[$clustercount].kubernetes.kubernetestype" $input)
  kubernetes_networkfabric=$(jq -r ".clusters[$clustercount].kubernetes.networkfabric" $input)

  kubernetes_networkfabricparameters=$(jq -r ".clusters[$clustercount].kubernetes.networkfabricparameters" $input)
  # replace temporary space character, because it causes issues with bash arrays
  kubernetes_networkfabricparameters="${kubernetes_networkfabricparameters//[ ]/'%'}"

  kubernetes_version=$(jq -r ".clusters[$clustercount].kubernetes.kubernetesversion" $input)
  containerd_version=$(jq -r ".clusters[$clustercount].kubernetes.containerdversion" $input)
  critools_version=$(jq -r ".clusters[$clustercount].kubernetes.critoolsversion" $input)
  kubernetes_networkcidr=$(jq -r ".clusters[$clustercount].kubernetes.networkcidr" $input)
  kubernetes_servicecidr=$(jq -r ".clusters[$clustercount].kubernetes.servicecidr" $input)

  # importing applications
  # create counter
  appcount=0
  # create empty arrays
  app_names=()
  app_versions=()
  app_parameters=()
  app_sharedfiles=()
  app_waitsforfiles=()
  app_scopes=()
  app_deployed=()

  for name in `jq -r ".clusters[$clustercount].applications[].name" $input`
  do
     appversion=`jq -r ".clusters[$clustercount].applications[$appcount].version" $input`
     appparameters=`jq -r ".clusters[$clustercount].applications[$appcount].parameters" $input`
     # replace temporary space character, because it causes issues with bash arrays
     appparameters="${appparameters//[ ]/'%'}"    
     appsharefile=`jq -r ".clusters[$clustercount].applications[$appcount].sharefile" $input`
     appwaitforfile=`jq -r ".clusters[$clustercount].applications[$appcount].waitforfile" $input`
     appscope=`jq -r ".clusters[$clustercount].applications[$appcount].scope" $input`
     appdeployed=`jq -r ".clusters[$clustercount].applications[$appcount].deployed" $input`

     app_names+=($name)
     app_versions+=($appversion)
     app_parameters+=($appparameters)
     app_sharedfiles+=($appsharefile)
     app_waitsforfiles+=($appwaitforfile)
     app_scopes+=($appscope)
     app_deployed+=($appdeployed)

     let appcount=appcount+1
  done

  # convert to "" some missing declarations
  if [[ -z $infrastructure_masters_os ]]
  then
    infrastructure_masters_os=""
  fi

  if [[ -z $infrastructure_masters_osaccount ]]
  then
    infrastructure_masters_osaccount=""
  fi

  if [[ -z $infrastructure_workers_os ]]
  then
    infrastructure_workers_os=""
  fi

  if [[ -z $infrastructure_workers_osaccount ]]
  then
    infrastructure_workers_osaccount=""
  fi

  if [[ -z $kubernetes_type ]]
  then
    kubernetes_type=""
  fi

  # generates slicerequest object
  source /opt/clusterslice/generate_slicerequest.sh > /tmp/$clustername-slicerequest.yaml

  # create slicerequest in user namespace
  kubectl apply -f /tmp/$clustername-slicerequest.yaml

  if [ $? -ne 0 ]; then
    echo "Cannot create slicerequest"
    # report status to multiclusterslicerequest (failed)
    report_multiclusterslicerequest_status $clusterslice_name "failed" $user_namespace
    exit 1
  fi

  let clustercount=clustercount+1
done
