#!/bin/bash

# kubernetes API updating functions
source /opt/clusterslice/benchmarking.sh

function change_resource_status () {
   # changing resource status in kubernetes API
   # first parameter is resource name
   # second parameter the new status
   local name=$1
   local status=$2
   local namespace=$3
   local original_status=""
   local pod_status=""
   #slice=$4

   # do that in the case of kubernetes
   if $k8s; then
     echo "change_resource_status name $name status $status namespace $namespace"

     # be sure that resource is not currently terminating, but do not have this check for "reserved" status
     if [[ ! $status == "reserved" ]]; then
       pod_status=$(kubectl get pod resource-manager-$name --namespace $namespace -o jsonpath='{.status.phase}')
     fi

     # get original status
     original_status=$(get_resource_status $name $namespace)

     if [[ ! $pod_status == "Terminating" ]]; then
        #echo "Change resource $name status to '$status'" 
        # free can only become reserved (e.g., may become booting during slice removal)
	if [[ original_status == "free" ]] && [[ status == "booting" ]]; then
	  echo "cannot switch resource status from free to booting."
	else
	  #if [[ original_status == "os_ready" ]] && [[ status == "reserved" ]]; then
	  #  echo "cannot switch resource status from os_ready to reserved, it is probably a testbed node."
	  #else
	  kubectl patch cr/$name --patch "{\"spec\":{\"status\":\"$status\"}}" -n $namespace --type merge
	  #fi
	fi
     else
	echo "Pod is currently in terminating state, skipping changing resource status."
     fi
   else
      # change environment variable for resource status
      change_nonk8s_resource_status $status
   fi

   #echo "Change resource $name slice to '$slice'" 
   #kubectl patch cr/$name --patch "{\"spec\":{\"slice\":\"$slice\"}}" -n $namespace --type merge
}

function change_nonk8s_resource_status () {
   local newstatus=$1
   echo "$newstatus" > $statusfile
}

function wait_all_nonk8s_workers_for_status () {
   local targetstatus=$1
   local trueforall=false

   while ! $trueforall; do
     countall=0
     countstatus=0
     for workerhost in $worker_hosts;
     do
       filename=$main_path/shared/$workerhost-status
       status=`cat $filename`
       if [[ "$status" == "$targetstatus" || "$status" == "allocated" ]]; then
          let countstatus=countstatus+1
       fi
       let countall=countall+1
     done
     if [[ $countall -eq $countstatus ]]; then
       trueforall=true
     fi
   done
}

function change_resource_slice () {
   # changing resource status in kubernetes API
   # first parameter is resource name
   # second parameter the new status
   local name=$1
   local slice=$2
   local testbed_namespace=$3
   local user_namespace=$4

   # do that only in the case of k8s, otherwise use an environment variable
   if $k8s; then
     echo "change_resource_slice name $name slice $slice testbed_namespace $testbed_namespace user_namespace $user_namespace"

     #echo "Change resource $name slice to '$slice'" 
     kubectl patch cr/$name --patch "{\"spec\":{\"slice\":\"$slice\"}}" -n $testbed_namespace --type merge

     kubectl patch cr/$name --patch "{\"spec\":{\"usernamespace\":\"$user_namespace\"}}" -n $testbed_namespace --type merge
   else
     export SLICE=$slice
   fi
}

function get_resource_status () {
  local name=$1
  local namespace=$2

  # get resource status, in the case of k8s, otherwise return env variable
  if $k8s; then
    kubectl get cr/$name -n $namespace -o=jsonpath="{.spec.status}"
  else
    get_nonk8s_resource_status
  fi
}

function get_nonk8s_resource_status () {
  cat $statusfile
}

function get_resource_app () {
  local name=$1
  local namespace=$2

  #echo "get_resource_app name $name namespace $namespace"

  # get resource app value in the case of k8s, otherwise return env variable
  if $k8s; then
    kubectl get cr/$name -n $namespace -o=jsonpath="{.spec.apps}"
  else
    echo $APPS
  fi
}

function check_if_app_is_installed () {
  local name=$1
  local app=$2
  local namespace=$3

  # in the case of k8s, read api
  if $k8s; then
    existing_apps=`get_resource_app $name $namespace`
  else
    existing_aps=$APPS
  fi
  installed=false
  for installed_app in $existing_apps; do
     if [[ $installed_app == $app ]]; then
        installed=true
     fi
  done

  echo $installed
}

function change_resource_app () {
   # changing resource status in kubernetes API
   # first parameter is resource name
   # second parameter the new status
   local name=$1
   local app=$2
   local namespace=$3

   # execute in the case of k8s, otherwise use env variable APPS
   if $k8s; then
     echo "change_resource_app name $name app $app namespace $namespace"

     #echo "Change resource $name app to '$app'"
     existing_app=`get_resource_app $name $namespace`

     if [[ $existing_app == "" ]]; then
       new_app="$app"
     else
       new_app="$existing_app $app"
     fi

     kubectl patch cr/$name --patch "{\"spec\":{\"apps\":\"$new_app\"}}" -n $namespace --type merge
   else
     # use env variable APPS (for docker based deployments)
     existing_app=$APPS

     if [[ $existing_app == "" ]]; then
       new_app="$app"
     else
       new_app="$existing_app $app"
     fi

     export APPS=$new_app
   fi
}

function report_slicerequest_status () {
  local name=$1
  local status=$2
  local namespace=$3

  echo "report_slicerequest_status name $name status $status namespace $namespace"

  # report status to slicerequest (e.g., accepted)
  kubectl patch slr/$name --patch "{\"spec\":{\"status\":\"$status\"}}" -n $namespace --type merge
}

function report_multiclusterslicerequest_status () {
  local name=$1
  local status=$2
  local namespace=$3

  echo "report_multiclusterslicerequest_status name $name status $status namespace $namespace"

  # report status to multiclusterslicerequest (accepted)
  kubectl patch mcslr/$name --patch "{\"spec\":{\"status\":\"$status\"}}" -n $namespace --type merge
}


function mark_slice_apps_deployed () {
  local name=$1
  local namespace=$2

  local count=0

  # make sure that application field is not null
  applications=`kubectl -n $namespace get sl/$name -o json | jq -r ".spec.applications"`

  if [[ $applications != "null" ]]; then
     for app in `kubectl -n $namespace get sl/$name -o json | jq -r ".spec.applications[].name"`
     do
       patch="[{\"op\": \"replace\", \"path\": \"/spec/applications/$count/deployed\", \"value\":true}]"
       kubectl patch -n $namespace slice $name --type='json' -p="$patch"

       let count=count+1
     done
  fi
}

function update_slice_app () {
  local name=$1
  local app_count=$2
  local parameter=$3
  local value=$4
  local namespace=$5

  echo "update_slice_app name $name app_count $app_count parameter $parameter value $value namespace $namespace"

  #echo "kubectl patch -n $namespace slice $name --type='json' -p=\"[{\"op\": \"replace\", \"path\": \"/spec/applications/$app_count/$parameter\", \"value\":$value}]\""
  patch="[{\"op\": \"replace\", \"path\": \"/spec/applications/$app_count/$parameter\", \"value\":$value}]"

  echo "kubectl patch -n $namespace slice $name --type='json' -p='$patch'"

  kubectl patch -n $namespace slice $name --type='json' -p='$patch'
}

function update_slice_status_and_output () {
  local name=$1
  local status=$2
  local output=$3
  local namespace=$4

  echo "update_slice_status_and_output name $name status $status output $output $namespace $namespace"

  kubectl patch sl/$name --patch "{\"spec\":{\"status\":\"$status\"}}" -n $namespace --type merge
  kubectl patch sl/$name --patch "{\"spec\":{\"output\":\"$output\"}}" -n $namespace --type merge

  # benchmarking slice operations
  benchmark_slice ${name} $status 
}

function get_slice_status () {
  local name=$1
  local namespace=$2

  echo "get_slice_status name $name namespace $2"


  kubectl get sl/$name -n $namespace -o=jsonpath="{.spec.status}"
}

function update_slice_master_nodes () {
  local slice=$1
  local nodes=$2
  local namespace=$3

  echo "update_slice_master_nodes slice $slice nodes $nodes namespace $namespace"

  kubectl patch sl/$slice --patch "{\"spec\":{\"infrastructure\":{\"masters\":\"$nodes\"}}}" -n $namespace --type merge
}

function update_slice_worker_nodes () {
  local slice=$1
  local nodes=$2
  local namespace=$3

  echo "update_slice_worker_nodes slice $slice nodes $nodes namespace $namespace"

  kubectl patch sl/$slice --patch "{\"spec\":{\"infrastructure\":{\"workers\":\"$nodes\"}}}" -n $namespace --type merge
}

function copysecret () {
  local secret=$1
  local testbed_namespace=$2
  local user_namespace=$3

  if [[ $testbed_namespace == $user_namespace ]]; then
    echo "secret is already there."
  else
    echo "copying secret $secret from namespace $testbed_namespace to namespace $user_namespace"

    # copying a secret from swn namespace to the user namespace.
    # delete it if it already exists
    kubectl delete secret $secret -n $user_namespace 2> /dev/null
    kubectl get secret $secret -n $testbed_namespace -o yaml \
      | sed "s/namespace: $testbed_namespace/namespace: $user_namespace/" \
      | kubectl apply -n $user_namespace --filename -;
  fi
}


# other helper functions

function wait_for_ssh () {

  local hostname=$1

  ssh $hostname "echo 'Host is up!'"
  while test $? -gt 0
  do
    sleep 5 # highly recommended - if it's in your local network, it can try an awful lot pretty quick...
    echo "Trying again..."

    # this is the first ssh connection to the node from the particular container
    # the -o StrictHostKeyChecking=no parameter allows the addition of the cloud
    # node to the known_hosts, without asking confirmation.
    ssh $hostname -o StrictHostKeyChecking=no "echo 'Host is up!'"
  done
}

function json_array () {
  # syntax:
  # json_array "${X[@]}"
  echo -n '['
  while [ $# -gt 0 ]; do
    x=${1//\\/\\\\}
    echo -n \"${x//\"/\\\"}\"
    #echo -n \'${x//\"/\\\"}\'
    [ $# -gt 1 ] && echo -n ', '
    shift
  done
  echo ']'
}

function json_array_items () {
  # extracts items from json array
  # input is the json_array string - it should be passed with double quotes

  local json_array=$1

  echo $json_array | jq -c -r '.[]'
}

function json_array_item () {
  # extracts a particular item from json array
  # inputs are the json_array string (pass it with double quotes) and the item's position

  local json_array=$1
  local item=$2

  echo "$json_array" | jq -c -r ".[$item]"
}

function convert_to_spaced_strings () {
   # strips comma from string
   local input=$1

   input=${input//"{"/''}
   input=${input//"}"/''}
   input=${input//[,]/' '}   
   echo $input
}

function convert_to_spaced_strings_without_brackets () {
   # strips comma from string
   local input=$1

   input=${input//"["/''}
   input=${input//"{"/''}
   input=${input//"]"/''}
   input=${input//"}"/''}
   input=${input//[,]/' '}
   echo $input
}

function convert_to_suitable_string () {
   # strips comma from string
   local input=$1

   input=${input//"},{"/'} {'}
   #input=${input//[\}]/')"'}
   #input=${input//[,]/' '}   
   echo $input
}

# Validate if the input is a valid JSON array
validate_json_array() {
    local input="$1"
    if [[ ! -z "$input" ]]; then 
      if [[ ! $input == "[]" ]]; then
        #if [[ ! "$input" =~ ^\[[^\]]*\]$ ]]; then
        if [[ ! "$input" =~ ^\[[^\]]*(\".*\"|\[.*\]|[^\"\[\]]*)[^\]]*\]$ ]]; then
           echo "Invalid JSON array: $input"
           exit 1
	fi
      fi
    fi
}

function validate_input() {
   # first parameter is the variable itself (without $ chracter)
   # second the env variable name
   # third (optional) is the default value for empty variables
   
   # get first variable byref
   local -n input=$1

   if [[ -z "$input" ]] || [[ $input == "" ]] ; then
      if [[ -z "$3" ]]; then
         echo "Error: $2 input variable is required."
         exit 1
      else
	 input="$3" 
      fi
   fi
}
