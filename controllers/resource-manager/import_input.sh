#!/bin/bash

# import input variables, variables required from k8s based execution
# generic configuration
if $k8s; then
  clusterslice_name=$CLUSTERSLICE_NAME
  user_namespace=$USER_NAMESPACE
else
  clusterslice_name="standalone"
  user_namespace="standalone"
fi

# access credentials
admin_username=$ADMIN_USERNAME
admin_password=$ADMIN_PASSWORD

# details of cloud server
cloud_ip=$CLOUD_IP
cloud_name=$CLOUD_NAME
cloud_operator=$CLOUD_OPERATOR

# kubernetes details
kubernetes_type=$KUBERNETES_TYPE
kubernetes_networkfabric=$KUBERNETES_NETWORKFABRIC
kubernetes_networkcidr=$KUBERNETES_NETWORKCIDR
kubernetes_servicecidr=$KUBERNETES_SERVICECIDR
kubernetes_version=$KUBERNETES_VERSION
containerd_version=$CONTAINERD_VERSION
critools_version=$CRITOOLS_VERSION

# node details
node_name=$NODE_NAME
node_type=$NODE_TYPE
node_osimage=$NODE_OSIMAGE
node_osaccount=$NODE_OSACCOUNT
node_ip=$NODE_IP
node_mac=$NODE_MAC
node_secondaryip=$NODE_PRIVATEIP
node_secondarymac=$NODE_PRIVATEMAC

# Validate input
# Minimum variables required for standalone execution are node_name and node_ip

# Validate access credentials
validate_input admin_username "ADMIN_USERNAME" "none"
validate_input admin_password "ADMIN_PASSWORD" "none"

# Validate cloud server details
validate_input cloud_ip "CLOUD_IP" "none"
validate_input cloud_name "CLOUD_NAME" "none"
validate_input cloud_operator "CLOUD_OPERATOR" "none"

# Validate Kubernetes details
validate_input kubernetes_type "KUBERNETES_TYPE" "none"
validate_input kubernetes_networkfabric "KUBERNETES_NETWORKFABRIC" "none"
validate_input kubernetes_networkcidr "KUBERNETES_NETWORKCIDR" "10.244.0.0/16"
validate_input kubernetes_servicecidr "KUBERNETES_SERVICECIDR" "10.96.0.0/12"
validate_input kubernetes_version "KUBERNETES_VERSION" "none"
validate_input containerd_version "CONTAINERD_VERSION" "none"
validate_input critools_version "CRITOOLS_VERSION" "none"

# Validate node details
validate_input node_name "NODE_NAME"
validate_input node_type "NODE_TYPE" "none"
validate_input node_osimage "NODE_OSIMAGE" "none"
validate_input node_osaccount "NODE_OSACCOUNT" "user"
validate_input node_ip "NODE_IP" 
validate_input node_mac "NODE_MAC" "none"
validate_input node_secondaryip "NODE_PRIVATEIP" "none"
validate_input node_secondarymac "NODE_PRIVATEMAC" "none"

# Validate application input
app_names=$APP_NAMES
app_scopes=$APP_SCOPES
app_parameters=$APP_PARAMETERS
app_versions=$APP_VERSIONS
app_sharedfiles=$APP_SHAREDFILES
app_waitforfiles=$APP_WAITSFORFILES
app_deployed=$APP_DEPLOYED

# Validate if they are json arrays
validate_json_array "$app_names"

# Get the size of the app_names array
app_names_array=($(echo "$app_names" | jq -r '.[]'))
app_names_array_size=${#app_names_array[@]}
default_array=""

#echo "apps array size is $app_names_array_size"

if [[ $app_names_array_size -gt 0 ]]; then
  default_array=$(printf '"all",%.0s' $(seq 1 $app_names_array_size) | sed 's/,$//')
fi

# Validate if they are json arrays
validate_json_array "$app_scopes"
# Set default values in the case they are empty 
if [[ -z "$app_scopes" ]]; then
   app_scopes=[$default_array]
fi

if [[ $app_names_array_size -gt 0 ]]; then
   default_array=$(printf '"none",%.0s' $(seq 1 $app_names_array_size) | sed 's/,$//')
fi

# Validate if they are json arrays 
# remove double quote escaping
cleaned_json=$(echo "$app_parameters" | sed 's/\\"/"/g')
validate_json_array "$cleaned_json"
# Set default values in the case they are empty
if [[ -z "$app_parameters" ]]; then
   app_parameters=[$default_array]
fi

# Validate if they are json arrays
validate_json_array "$app_versions"
# Set default values in the case they are empty
if [[ -z "$app_versions" ]]; then
   app_versions=[$default_array]
fi

# Validate if they are json arrays
validate_json_array "$app_sharedfiles"
# Set default values in the case they are empty
if [[ -z "$app_sharedfiles" ]]; then
   app_sharedfiles=[$default_array]
fi

# Validate if they are json arrays
validate_json_array "$app_waitforfiles"
# Set default values in the case they are empty
if [[ -z "$app_waitforfiles" ]]; then
   app_waitforfiles=[$default_array]
fi

if [[ $app_names_array_size -gt 0 ]]; then
  default_array=$(printf '"false",%.0s' $(seq 1 $app_names_array_size) | sed 's/,$//')
fi

# Validate if they are json arrays
validate_json_array "$app_deployed"
# Set default values in the case they are empty
if [[ -z "$app_deployed" ]]; then
   app_deployed=[$default_array]
fi

# debug output of application configuration
#echo "app_names=$app_names"
#echo "app_scopes=$app_scopes"
#echo "app_parameters=$app_parameters"
#echo "app_versions=$app_versions"
#echo "app_sharedfiles=$app_sharedfiles"
#echo "app_waitforfiles=$app_waitforfiles"
#echo "app_deployed=$app_deployed"

# set status tracking filename
statusfile=$main_path/shared/$node_name-status

# set default resource status, in the case of non-k8s and no status is yet set
if ! $k8s; then
   #echo "checking status file existence"
   if [ ! -f "$statusfile" ]; then
      #echo "creating status file"
      echo "reserved" > $statusfile
   fi
fi

# get slice nodes, i.e., for cluster information in /opt/info folder
master_ips=$(json_array_items "$MASTER_IPS")
master_secondaryips=$(json_array_items "$MASTER_PRIVATEIPS")
master_hosts=$(json_array_items "$MASTER_HOSTS")
worker_ips=$(json_array_items "$WORKER_IPS")
worker_secondaryips=$(json_array_items "$WORKER_PRIVATEIPS")
worker_hosts=$(json_array_items "$WORKER_HOSTS")

# get first master for cluster deployments
first_master_name=$(json_array_item "$MASTER_HOSTS" 0)
first_master_ip=$(json_array_item "$MASTER_IPS" 0)
first_master_secondaryip=$(json_array_item "$MASTER_PRIVATEIPS" 0)

# create ansible hosts file, example:
# kubem1 ansible_ssh_host=195.251.209.228 ansible_ssh_port=22 ansible_ssh_user=user
# node_name, node_ip, node_osaccount, $main_path/ansible/hosts
# do that for k8s execution, only
if $k8s; then
  echo "creating ansible file for host."
  if [[ $node_ip == "none" ]] || [[ $node_ip == "" ]]; then
    # no public ip is present, use secondary ip instead
    echo "$node_name ansible_ssh_host=${node_secondaryip} ansible_ssh_port=22 ansible_ssh_user=$node_osaccount" > $main_path/ansible/hosts
  else
    echo "$node_name ansible_ssh_host=${node_ip} ansible_ssh_port=22 ansible_ssh_user=$node_osaccount" > $main_path/ansible/hosts
  fi
fi
#echo "" >> $main_path/ansible/hosts
#echo "[all:vars]" >> $main_path/ansible/hosts
#echo "ansible_ssh_common_args='-o StrictHostKeyChecking=no'" >> $main_path/ansible/hosts

# create a file with master nodes in ansible playbooks files folder
rm $playbook_path/files/masters 2> /dev/null
resinputcount=0
for masterhost in $master_hosts;
do
  # store both public and private IPs for master nodes, i.e., needed from submariner
  if [[ $node_secondaryip == "none" ]] || [[ $node_secondaryip == "" ]]; then
     masterip=$(json_array_item "$MASTER_IPS" $resinputcount)
     #echo "$masterip $masterhost" >> $playbook_path/files/masters
  else
     masterip=$(json_array_item "$MASTER_PRIVATEIPS" $resinputcount)
     #echo "$masterip $masterhost" >> $playbook_path/files/masters
     # store also public
     #masterip=$(json_array_item "$MASTER_IPS" $resinputcount)
     #echo "$masterip $masterhost" >> $playbook_path/files/masters
  fi
  echo "$masterip $masterhost" >> $playbook_path/files/masters
  let resinputcount=resinputcount+1
done

# keep number of master nodes
masters_num=$resinputcount

# create a file with worker nodes in ansible playbooks files folder
rm $playbook_path/files/workers 2> /dev/null
resinputcount=0
for workerhost in $worker_hosts;
do
  # the primary IP is used in the cluster, if no private network is present
  if [[ $node_secondaryip == "none" ]] || [[ $node_secondaryip == "" ]]; then
     workerip=$(json_array_item "$WORKER_IPS" $resinputcount)
  else
     workerip=$(json_array_item "$WORKER_PRIVATEIPS" $resinputcount)
  fi
  echo "$workerip $workerhost" >> $playbook_path/files/workers
  let resinputcount=resinputcount+1
done

# keep number of master nodes
workers_num=$resinputcount
