#!/bin/bash

# defines main path
main_path=/opt/clusterslice/

# define test-bed gateway
gateway="TBA"
# define test-bed DNS
dns="8.8.8.8"

# define hosts file name and playbook directory
hostsfile=$main_path/ansible/hosts
playbook_path=$main_path/playbooks

# define test-bed namespace (i.e., for slicerequest & slice operators as well as computeresources) 
testbed_namespace="swn"

# define ansible trailer
ansible_trailer="ansible_ssh_host=ip ansible_ssh_port=22 ansible_ssh_user=user"
ansible_debug="" #-vvv

# enable infrastructure managers
enable_virtualbox=false
enable_xcpng=false
enable_cloudlab=false

# enable DHCP server
enable_DHCP=true

# image prefix (i.e., define it in the case of a private image repository)
#image_prefix=""

# define if containers are being pushed in the repository or not
push_images=false

# one can disable it and create a docker container out of resource-manager
if [ -z "$K8S" ]; then
   k8s=true
else
   k8s=$K8S
fi
