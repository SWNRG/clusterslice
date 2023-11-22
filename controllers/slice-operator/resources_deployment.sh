#!/bin/bash

# global variables are:
# clusterslice_name
# kubernetes_type
# kubernetes_networkfabric
# kubernetes_networkcidr
# kubernetes_servicecidr
# kubernetes_version
# containerd_version
# critools_version
# admin_username
# admin_password
# masters_hosts
# masters_osimages
# masters_osaccounts
# masters_types
# masters_ips
# masters_macs
# masters_secondaryips
# masters_secondarymacs
# masters_server_ips
# masters_server_names
# masters_server_operators
# workers_hosts
# workers_osimages
# workers_osaccounts
# workers_types
# workers_ips
# workers_macs
# workers_secondaryips
# workers_secondarymacs
# workers_server_ips
# workers_server_names
# workers_server_operators
# app_names
# app_versions
# app_parameters 
# app_sharedfiles
# app_waitsforfiles
# app_scopes
# app_deployed

# fix app_parameters space issue

# define default image_prefix, if it is not set
if [[ -z "$image_prefix" ]]; then
  image_prefix="swnrg"
fi

function create_pod_yaml () {

  # fix app_parameters space issue	
  appparameters=$(json_array ${app_parameters[@]})
  appparameters="${appparameters//[%]/' '}"
  # escape single quote to double quote
  appparameters="${appparameters//[\']/'\"'}"

cat > $filename << EOF
apiVersion: v1                                       
kind: Pod                                            
metadata:                                            
  name: resource-manager-$node_name                                   
  namespace: $user_namespace
  ownerReferences:
  - apiVersion: "swn.uom.gr/v1"
    kind: Slice
    name: $clusterslice_name
    uid: $uid
spec:                                                
  restartPolicy: Never
  containers:                                        
  - name: resource-manager-$node_name                       
    image: ${image_prefix}/resource-manager
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "/opt/clusterslice/start.sh" ]
    imagePullPolicy: Always
    lifecycle:
      preStop:
        exec:
          command: ["/bin/sh","-c","/opt/clusterslice/cleanup.sh \"$node_operator\" $node_serverip $node_name $testbed_namespace"]
    volumeMounts:
    - name: ssh-keys
      mountPath: "/etc/ssh"     
    env:
    - name: LOG_TYPE
      value: "text"
    - name: ANSIBLE_TIMEOUT
      value: "30"
    - name: CLUSTERSLICE_NAME
      value: $clusterslice_name
    - name: USER_NAMESPACE
      value: $user_namespace
    - name: CLOUD_IP
      value: $node_serverip
    - name: CLOUD_NAME
      value: $node_servername
    - name: CLOUD_OPERATOR
      value: $node_operator
    - name: NODE_NAME                          
      value: $node_name
    - name: NODE_TYPE                          
      value: $node_type
    - name: NODE_OSIMAGE                          
      value: $node_osimage
    - name: NODE_OSACCOUNT
      value: $node_osaccount
    - name: NODE_IP
      value: $node_ip
    - name: NODE_MAC
      value: $node_mac
    - name: NODE_PRIVATEIP
      value: $node_secondaryip
    - name: NODE_PRIVATEMAC
      value: $node_secondarymac
    - name: KUBERNETES_TYPE
      value: $kubernetes_type
    - name: KUBERNETES_NETWORKFABRIC
      value: $kubernetes_networkfabric
    - name: KUBERNETES_NETWORKCIDR
      value: $kubernetes_networkcidr
    - name: KUBERNETES_SERVICECIDR
      value: $kubernetes_servicecidr
    - name: KUBERNETES_VERSION
      value: '$kubernetes_version'
    - name: CONTAINERD_VERSION
      value: '$containerd_version'
    - name: CRITOOLS_VERSION
      value: '$critools_version'
    - name: ADMIN_USERNAME
      value: $admin_username
    - name: ADMIN_PASSWORD
      value: $admin_password
    - name: MASTER_IPS
      value: '$(json_array "${masters_ips[@]}")'
    - name: MASTER_PRIVATEIPS
      value: '$(json_array "${masters_secondaryips[@]}")'
    - name: MASTER_HOSTS
      value: '$(json_array "${masters_hosts[@]}")'
    - name: WORKER_IPS
      value: '$(json_array "${workers_ips[@]}")'
    - name: WORKER_PRIVATEIPS
      value: '$(json_array "${workers_secondaryips[@]}")'
    - name: WORKER_HOSTS
      value: '$(json_array "${workers_hosts[@]}")'
    - name: APP_NAMES
      value: '$(json_array "${app_names[@]}")'
    - name: APP_VERSIONS
      value: '$(json_array "${app_versions[@]}")'
    - name: APP_SHAREDFILES
      value: '$(json_array "${app_sharedfiles[@]}")'
    - name: APP_WAITSFORFILES
      value: '$(json_array "${app_waitsforfiles[@]}")'
    - name: APP_PARAMETERS
      value: '$appparameters'
    - name: APP_SCOPES
      value: '$(json_array "${app_scopes[@]}")'
    - name: APP_DEPLOYED
      value: '$(json_array "${app_deployed[@]}")'
  serviceAccountName: monitor-clusterslice
  imagePullSecrets:
  - name: registry-secret
  volumes:
  - name: ssh-keys
    secret:
      secretName: ssh-secret
      defaultMode: 0600
EOF
}

# iterate through all master nodes

# create file that keeps active master management pods
rm /tmp/$clusterslice_name-masters 2> /dev/null 
touch /tmp/$clusterslice_name-masters

for arrayindex in ${!masters_hosts[@]};
do
  node_name=${masters_hosts[$arrayindex]}
  node_type=${masters_types[$arrayindex]}
  node_osimage=${masters_osimages[$arrayindex]}
  node_osaccount=${masters_osaccounts[$arrayindex]}
  node_ip=${masters_ips[$arrayindex]}
  node_mac=${masters_macs[$arrayindex]}
  node_secondaryip=${masters_secondaryips[$arrayindex]}
  node_secondarymac=${masters_secondarymacs[$arrayindex]}
  node_serverip=${masters_server_ips[$arrayindex]}
  node_servername=${masters_server_names[$arrayindex]}
  node_operator=${masters_server_operators[$arrayindex]}

  # create a new pod yaml file
  filename="resource-manager-$node_name-pod.yaml"

  # wait for a previous pod to be terminated (i.e., in the case of a previous removal)
  #kubectl wait --for=delete -n swn pod/resource-manager-$node_name --timeout=300s

  # create yaml of pod
  create_pod_yaml

  # execute new pod
  kubectl apply -f $filename

  # store master name for later usage
  echo "$node_name" >> /tmp/$clusterslice_name-masters

#properties                                          
#server_ip=$server_ip                                  
#server_name=$server_name                                   
#node_name=$node_name                                
#node_type=$node_type                                
#node_osimage=$node_osimage
#node_ip=$node_ip                                    
#node_mac=$node_mac
#node_secondaryip=$node_secondaryip                                    
#node_secondarymac=$node_secondarymac
#admin_username=$admin_username
#admin_password=$admin_password

done

# iterate through all worker nodes         

# create file that keeps active worker management pods
rm /tmp/$clusterslice_name-workers 2> /dev/null 
touch /tmp/$clusterslice_name-workers

for arrayindex in ${!workers_hosts[@]};
do
  node_name=${workers_hosts[$arrayindex]}
  node_type=${workers_types[$arrayindex]}
  node_osimage=${workers_osimages[$arrayindex]}
  node_osaccount=${workers_osaccounts[$arrayindex]}
  node_ip=${workers_ips[$arrayindex]}
  node_mac=${workers_macs[$arrayindex]}
  node_secondaryip=${workers_secondaryips[$arrayindex]}
  node_secondarymac=${workers_secondarymacs[$arrayindex]}
  node_serverip=${workers_server_ips[$arrayindex]}
  node_servername=${workers_server_names[$arrayindex]}
  node_operator=${workers_server_operators[$arrayindex]}

  # create a new pod yaml file
  filename="resource-manager-$node_name-pod.yaml"

  # wait for a previous pod to be terminated (i.e., in the case of a previous removal)
  #kubectl wait --for=delete -n swn pod/resource-manager-$node_name --timeout=300s

  # create yaml of pod
  create_pod_yaml

  # execute pod
  kubectl apply -f $filename

  # store worker name for later usage
  echo "$node_name" >> /tmp/$clusterslice_name-workers
done
