#!/bin/bash

function create_playbook () {
   # creates and configures a new playbook 
   local playbookname=$1

   # create a new file from playbook template
   cp $playbook_path/$playbookname.template $playbook_path/${playbook_prefix}${playbookname}
   # update template
   input=$2[@]
   keyvalues=("${!input}")
   
   for keyvalue in ${keyvalues[@]}; do
      #echo $keyvalue
      cleaned_keyvalue=${keyvalue/','/' '}
      key=""
      for item in $cleaned_keyvalue; do
         if [[ -z $key ]] 
         then
           key=$item
         else
           #value=$item
	   # strip value from brackets as well
	   value=`convert_to_spaced_strings_without_brackets $item`
	   # replace additional spaces that may appear after stripping value
           value=${value//' '/'\ '}
         fi
      done
      echo "Replacing key $key for value $value."
      # remove '' for ubuntu (it is there for mac-os-x compatibility)
      if [ `uname` == "Linux" ]; then
         sed -i "s $key $value g" $playbook_path/${playbook_prefix}${playbookname}
      else
         sed -i "" "s $key $value g" $playbook_path/${playbook_prefix}${playbookname}     
      fi
   done
   # replace missing {@variables@} with the word none
   if [ `uname` == "Linux" ]; then
         sed -i "s {@.*@} none g" $playbook_path/${playbook_prefix}${playbookname}
   else
         sed -i "" "s {@.*@} none g" $playbook_path/${playbook_prefix}${playbookname}
   fi
}

function wait_for_node_to_bootup () { 
   # function that waits for node to boot up
   #ping $1 | grep --line-buffered "bytes from" | head -1
   
   # should wait for SSH rather than ping
   wait_for_ssh $1
}

function create_vm_and_install_os () {
  # parameters $node_name $node_type $node_ip $node_mac $node_secondaryip $node_secondarymac $node_osimage $cloud_ip $cloud_operator $testbed_namespace
  local node_name=$1
  local node_type=$2
  local node_ip=$3
  local node_mac=$4
  local node_secondaryip=$5
  local node_secondarymac=$6
  local node_osimage=$7
  local cloud_ip=$8
  local cloud_operator=$9
  local testbed_namespace=${10}

  echo "Allocating node $node_name of type $node_type."
  change_resource_status $node_name "creating_vm" $testbed_namespace
  # create VM from template
  import_vm_from_template $cloud_operator $cloud_ip $node_name $node_ip $node_mac $node_secondaryip $node_secondarymac $node_osimage
}

function import_vm_from_template () {
  # imports a new VMs from a particular template, based on direct ssh command
  # parameters: $cloud_operator $cloud_ip $node_name $node_ip $node_mac $node_secondaryip $node_secondarymac $node_osimage
  local operator=$1
  local cloud_server=$2
  local vm=$3
  local ip=$4
  local mac=$5
  local secondaryip=$6
  local secondarymac=$7
  local template=$8
  
  # communicate with the cloud server directly, in the case no operator parameter has been passed

  if [[ $operator == "" ]] || [[ $operator == "none" ]]; then 
    echo "Requesting cloud server $cloud_server to create VM $vm with mac $mac from template $template."
  
    # connect to cloud server and import VM from template
    # this is the first ssh connection to the server from the particular container
    # the -o StrictHostKeyChecking=no parameter allows the addition of the cloud
    # node to the known_hosts, without asking confirmation.
    retcode=$(ssh root@$cloud_server -o StrictHostKeyChecking=no "/root/deploy_infrastructure_resource.sh $cloud_server $vm $mac $secondarymac $template; echo \$?" 2>/dev/null)

    # show output
    ssh root@$cloud_server -o StrictHostKeyChecking=no "cat /tmp/output-$vm.txt"

    # terminate deploying slice, in the case ssh returns an error code
    if [ $retcode -eq 0 ]; then
       echo "The VM has been imported successfully."
    else
       exit 1
    fi
  else
    # request the particular operator to create the vm from template
    echo "Triggering operator $operator to request from cloud server $cloud_server to create VM $vm with mac $mac from template $template."

    # in the case of k8s, access container, otherwise IM scripts have been 
    # mounted locally in resource managers

    if $k8s; then
      kubectl exec $operator -- /root/deploy_infrastructure_resource.sh $cloud_server $vm $mac $secondarymac $template
      retcode=$?

      echo "returned code $retcode"

      # show output
      kubectl exec $operator -- cat /tmp/output-$vm.txt
    else
      # execute IM scripts that have been mounted locally in resource manager
      # create softlink to appropriate infrastructure manager
      ln -s /opt/clusterslice/$operator/* /root/ 
      
      # create IM termination script
      cat << EOF > /root/terminate.sh
#!/bin/bash

touch /opt/clusterslice/$operator/completed
EOF
      chmod +x /root/terminate.sh

      /root/deploy_infrastructure_resource.sh $cloud_server $vm $mac $secondarymac $template
      retcode=$?

      echo "returned code $retcode"

      # show output
      cat /tmp/output-$vm.txt
    fi

    # terminate deploying slice, in the case ssh returns an error code
    if [[ $retcode -eq 0 ]]; then
       echo "The VM has been imported successfully."
    else
       exit 1
    fi
  fi 

  # update resource status in kubernetes API
  #change_resource_status $vm "booting" $testbed_namespace

  echo "Waiting for node $vm to boot up."
  if [[ $ip == "none" ]] || [[ $ip == "" ]]; then
    # wait for secondary ip
    wait_for_node_to_bootup user@$secondaryip
  else
    # wait for public ip
    wait_for_node_to_bootup user@$ip
  fi
  #echo "Node is now up."
}

function configure_server () {
  # sets administrator credentials
  
  echo "Setting admin credentials of host $1 with IP $2 username $3 password $4 and kubernetestype $5."

  # create and set configure_server.yaml playbook
  echo "*** Creating and updating configure_server.yaml playbook ***"
  template_parameters=("{@node@},$1 {@username@},$3 {@password@},$4 {@kubernetestype@},$5")

  create_playbook "configure_server.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}configure_server.yaml #-c paramiko #-K

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The admin credentials have been set successfully."
  else
     exit 1
  fi

  #wait_for_node_to_bootup user@$2
}

function install_kubernetes_base () {
  # install basic kubernetes tools

  # import input:
  local node_name=$1
  local kubernetes_type=$2
  local kubernetes_version=$3
  local containerd_version=$4
  local critools_version=$5

  echo "Installing basic kubernetes tools in host $node_name."

  # create and set install_kubernetes_base.yaml playbook
  echo "*** Creating and updating install_kubernetes_base.yaml playbook ***"
  template_parameters=("{@hosts@},$node_name {@kubernetes_type@},$kubernetes_type {@username@},$admin_username {@kubernetes_version@},$kubernetes_version {@containerd_version@},$containerd_version {@critools_version@},$critools_version")

  create_playbook "install_kubernetes_base.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}install_kubernetes_base.yaml #-c paramiko

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The kubernetes basic tools have been installed successfully."
  else
     exit 1
  fi 
}

function install_kubernetes_master () {
  # install kubernetes master
  
  # import input:
  local node_name=$1 
  local admin_username=$2 
  local clusterslice_name=$3
  local kubernetes_type=$4
  local network_fabric=$5
  local network_fabric_parameters=$6
  local network_cidr=$7
  local service_cidr=$8
  local testbednamespace=$9
  local mastersnum=${10}
  local workersnum=${11}
  local apiserver=${12}

  # if no clusterslice_name is passed, define it as "manual" slice, i.e., created by manual_update_nodes.sh.
  if [[ -z $clusterslice_name ]]; then 
    clusterslice_name="manual"
  fi

  echo "Installing kubernetes master in host $node_name with username $admin_username."

  # create and set install_kubernetes_master.yaml playbook
  echo "*** Creating and updating install_kubernetes_master.yaml playbook ***"

  # adding all key-value parameters in a bash array
  template_parameters=()
  template_parameters+=({@host@},$node_name)
  template_parameters+=({@username@},$admin_username)
  template_parameters+=({@kubernetestype@},$kubernetes_type)
  template_parameters+=({@clusterslicename@},$clusterslice_name)
  template_parameters+=({@networkfabric@},$network_fabric)
  template_parameters+=({@networkcidr@},$network_cidr)
  template_parameters+=({@servicecidr@},$service_cidr)
  template_parameters+=({@testbednamespace@},$testbednamespace)
  template_parameters+=({@mastersnum@},$mastersnum)
  template_parameters+=({@workersnum@},$workersnum)
  template_parameters+=({@apiserver@},$apiserver)

  #template_parameters=("{@host@},$node_name {@username@},$admin_username {@kubernetestype@},$kubernetes_type {@clusterslicename@},$clusterslice_name {@networkfabric@},$network_fabric {@networkcidr@},$network_cidr {@servicecidr@},$service_cidr {@testbednamespace@},$testbednamespace {@mastersnum@},$mastersnum {@workersnum@},$workersnum {@apiserver@},$apiserver")


  # remove escape characters from network_fabric_parameters
  network_fabric_parameters=$(echo "$network_fabric_parameters" | sed 's/\\//g')

  # adding passed network fabric key-value parameters from yaml
  if [[ $network_fabric_parameters != "none" ]]; then
     echo "Passing additional parameters for kubernetes fabric: $network_fabric_parameters"
     passed_parameters=$(echo $network_fabric_parameters | jq -r 'to_entries|map("{@\(.key)@},\(.value)")|.[]')
     for parameter in $passed_parameters; do
       # add passed parameter
       template_parameters+=($parameter)
     done
  fi

  create_playbook "install_kubernetes_master.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}install_kubernetes_master.yaml -c paramiko
  
  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The kubernetes master has been installed successfully."
  else
     exit 1
  fi

  # if a master node is successfully installed, then create a secret with cluster join command
  # remove first the secret, if it already exist
  #kubectl delete secret $clusterslice_name-join-secret -n $testbed_namespace 2> /dev/null
  #kubectl create secret generic $clusterslice_name-join-secret --from-file=$playbook_path/$clusterslice_name-kubernetes_join_command -n $testbed_namespace

  # terminate deploying slice, in the case create secret returns an error code
  #if [ $? -eq 0 ]; then
  #   echo "The kubernetes join cluster command secret have been created successfully."
  #else
  #   exit 1
  #fi
}

function wait_for_cluster () {
  # waits for kubernetes cluster to complete, i.e., until kubectl get nodes command shows all nodes ready
  # this is needed for some network plugins that take time to be enabled (e.g., calico)

  # import input:
  local node_name=$1
  local admin_username=$2
  local kubernetes_type=$3

 echo "Waiting for kubernetes cluster to be completed in host $node_name with username $admin_username."

  # create and set wait_for_cluster.yaml playbook
  echo "*** Creating and updating wait_for_cluster.yaml playbook ***"
  template_parameters=("{@host@},$node_name {@username@},$admin_username {@kubernetestype@},$kubernetes_type")

  create_playbook "wait_for_cluster.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}wait_for_cluster.yaml -c paramiko

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The kubernetes cluster have been created successfully."
  else
     exit 1
  fi
}

function install_kubernetes_worker () {
  # install kubernetes worker
  local host=$1
  local admin_username=$2
  local kubernetestype=$3
  local network_fabric=$4
  local network_fabric_parameters=$5

  echo "Installing kubernetes worker in host $host with username $admin_username and kubernetes type $kubernetestype."

  # create and set install_kubernetes_worker.yaml playbook
  echo "*** Creating and updating install_kubernetes_worker.yaml playbook ***"
  template_parameters=("{@host@},$host {@username@},$admin_username {@kubernetestype@},$kubernetestype {@networkfabric@},$network_fabric")

  # remove escape characters from network_fabric_parameters
  network_fabric_parameters=$(echo "$network_fabric_parameters" | sed 's/\\//g')

  # adding passed network fabric key-value parameters from yaml
  if [[ $network_fabric_parameters != "none" ]]; then
     passed_parameters=$(echo $network_fabric_parameters | jq -r 'to_entries|map("{@\(.key)@},\(.value)")|.[]')
     for parameter in $passed_parameters; do
       # add passed parameter
       template_parameters+=($parameter)
     done
  fi

  create_playbook "install_kubernetes_worker.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}install_kubernetes_worker.yaml #-c paramiko
  
  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The kubernetes worker has been installed successfully."
  else
     echo "Cannot deploy clusterslice."
     exit 1
  fi 
}

function distribute_file () {
  # import input
  local app_name=$1
  local node_name=$2
  local admin_username=$3
  local app_sharefile=$4
  local user_namespace=$5

  echo "Sharing file $app_sharefile from $app_name in host $node_name with username $admin_username."

  # create and set playbook
  echo "*** Creating and updating distribute_file.yaml playbook ***"

  # adding all key-value parameters in a bash array
  template_parameters=()
  template_parameters+=({@node_name@},$node_name)
  template_parameters+=({@admin_username@},$admin_username)
  template_parameters+=({@app_name@},$app_name)
  template_parameters+=({@app_sharefile@},$app_sharefile)
  template_parameters+=({@user_namespace@},$user_namespace)

  create_playbook "distribute_file.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}distribute_file.yaml #-c paramiko

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The application $app_name shared file $app_sharefile successfully."
  else
     exit 1
  fi
}


function wait_for_file () {
  # import input
  local node_name=$1
  local admin_username=$2
  local app_waitforfile=$3

  echo "Waiting for file $app_waitforfile to appear in host $node_name with username $admin_username."

  # create and set playbook
  echo "*** Creating and updating wait_for_file.yaml playbook ***"

  # adding all key-value parameters in a bash array
  template_parameters=()
  template_parameters+=({@node_name@},$node_name)
  template_parameters+=({@admin_username@},$admin_username)
  template_parameters+=({@app_waitforfile@},$app_waitforfile)

  create_playbook "wait_for_file.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}wait_for_file.yaml #-c paramiko

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The file $app_waitforfile appeared successfully."
  else
     exit 1
  fi
}


function install_application () {
  # import input
  local app_name=$1
  local app_version=$2
  local app_sharefile=$3
  local app_waitforfile=$4
  local app_parameters=$5
  local node_name=$6
  local node_ip=$7
  local node_type=$8
  local admin_username=$9
  local clusterslice_name=${10}
  local user_namespace=${11}
  local kubernetes_type=${12}
  local kubernetes_version=${13}
  local containerd_version=${14}
  local critools_version=${15}

  echo "Installing application $app_name in host $node_name with username $admin_username."

  # start with waiting for an input file, if relevant
  if [[ $app_waitforfile != "none" ]]; then
    # wait for input file to appear
    wait_for_file $node_name $admin_username $app_waitforfile
  fi

  # create and set playbook
  echo "*** Creating and updating install_$app_name.yaml playbook ***"

  # adding all key-value parameters in a bash array
  template_parameters=()
  template_parameters+=({@node_name@},$node_name)
  template_parameters+=({@hosts@},$node_name)  # for compatibility with install_kubernetes_base
  template_parameters+=({@node_ip@},$node_ip)
  template_parameters+=({@node_type@},$node_type)
  template_parameters+=({@admin_username@},$admin_username)
  template_parameters+=({@app_name@},$app_name)
  template_parameters+=({@app_version@},$app_version)
  template_parameters+=({@clusterslice_name@},$clusterslice_name)
  template_parameters+=({@app_sharefile@},$app_sharefile)
  template_parameters+=({@app_waitforfile@},$app_waitforfile)
  template_parameters+=({@kubernetes_type@},$kubernetes_type)
  template_parameters+=({@kubernetes_version@},$kubernetes_version)
  template_parameters+=({@containerd_version@},$containerd_version)
  template_parameters+=({@critools_version@},$critools_version)

  #app_parameters=`convert_to_spaced_strings_without_brackets $app_parameters`

  # adding passed key-value parameters from yaml
  if [[ $app_parameters != "none" ]]; then
     passed_parameters=`echo $app_parameters | jq -r 'to_entries|map("{@\(.key)@},\(.value)")|.[]'`
     for parameter in $passed_parameters; do
       # add passed parameter
       template_parameters+=($parameter)
     done
  fi

  create_playbook "install_$app_name.yaml" template_parameters
  echo ""

  # execute playbook
  ansible-playbook $ansible_debug -i $hostsfile $playbook_path/${playbook_prefix}install_$app_name.yaml -c paramiko

  # terminate deploying slice, in the case ansible returns an error code
  if [ $? -eq 0 ]; then
     echo "The application $app_name has been installed and configured successfully."
  else
     exit 1
  fi
  # finalize with file distribution, if relevant
  if [[ $app_sharefile != "none" ]]; then
    # fetch and distribute shared file
    distribute_file $app_name $node_name $admin_username $app_sharefile $user_namespace
    # distribute fetched file to all other resource managers in the particular namespace
    #source $main_path/distribute_file.sh $app_sharefile $user_namespace
  fi
  # only in the case of application 'updates' wait again for cluster to boot up (only for master node)
  if [[ $app_name == "updates" ]] && ([[ $node_type == "mastervm" ]] || [[ $node_type == "masternode" ]]); then
     wait_for_cluster $node_name $admin_username $kubernetes_type
  fi
}
