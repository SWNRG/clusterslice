#!/bin/bash

# import configuration
source common_scripts/configuration.sh

# check if image prefix configuration is set
if [[ -z "$image_prefix" ]]; then
  # define default image prefix
  image_prefix="swnuom"
else
  # Loop through each .yaml.template file
  for template_file in *.yaml.template; do
    # Create the corresponding .yaml filename
    yaml_file="${template_file%.template}"

    # Replace the string and write to the .yaml file
    sed "s/swnuom/${image_prefix}/g" "${template_file}" > "${yaml_file}"
  done
fi

# build and upload multiclusterslicerequest-operator
echo "1) preparing multiclusterslicerequest-operator"
source ./build_controller.sh multiclusterslicerequest-operator

# build and upload slicerequest-operator
echo "2) preparing slicerequest-operator"
source ./build_controller.sh slicerequest-operator

# build and upload slice-operator
echo ""
echo "3) preparing slice-operator"
source ./build_controller.sh slice-operator

# build and upload resource-manager
echo ""
echo "4) preparing resource-manager"
source ./build_controller.sh resource-manager

# build and upload enabled infrastructure managers
echo ""
echo "5) preparing infrastructure managers"
if $enable_xcpng; then
  source ./build_controller.sh infrastructure-manager-xcpng
fi
if $enable_virtualbox; then
  source ./build_controller.sh infrastructure-manager-virtualbox
fi
if $enable_aws; then
  source ./build_controller.sh infrastructure-manager-aws
fi
if $enable_cloudlab; then
  source ./build_controller.sh infrastructure-manager-cloudlab
fi
if $enable_apt; then
  #source ./build_controller.sh infrastructure-manager-apt
  echo "For apt, we use the same image with cloudlab, for the time-being"
fi
if $enable_wisconsin; then
  #source ./build_controller.sh infrastructure-manager-wisconsin
  echo "For wisconsin, we use the same image with cloudlab, for the time-being"
fi
if $enable_wall2; then
  #source ./build_controller.sh infrastructure-manager-wall2
  echo "For wall2, we use the same image with cloudlab, for the time-being"
fi

# remove existing operators and infrastructure managers, in the case they exist
echo ""
echo "6) removing existing operators deployment and infrastructure managers, in the case they exist"
kubectl delete pod/multiclusterslicerequest-operator -n swn 2> /dev/null
kubectl delete pod/slicerequest-operator -n swn 2> /dev/null
kubectl delete pod/slice-operator -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-xcpng -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-virtualbox -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-aws -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-cloudlab -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-apt -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-wisconsin -n swn 2> /dev/null
kubectl delete pod/infrastructure-manager-wall2 -n swn 2> /dev/null

# create clusterslice operators and enabled infrastructure managers (resource-managers are being started during slice deployment processes).

echo ""
echo "7) starting clustersice operators and enabled infrastructure managers"
kubectl apply -f multiclusterslicerequest-operator-pod.yaml
kubectl apply -f slicerequest-operator-pod.yaml
kubectl apply -f slice-operator-pod.yaml

if $enable_xcpng; then
  kubectl apply -f infrastructure-manager-xcpng-pod.yaml
fi
if $enable_virtualbox; then
  kubectl apply -f infrastructure-manager-virtualbox-pod.yaml
fi
if $enable_aws; then
  kubectl apply -f infrastructure-manager-aws-pod.yaml
fi
if $enable_cloudlab; then
  kubectl apply -f infrastructure-manager-cloudlab-pod.yaml
fi
if $enable_apt; then
  kubectl apply -f infrastructure-manager-apt-pod.yaml
fi
if $enable_wisconsin; then
  kubectl apply -f infrastructure-manager-wisconsin-pod.yaml
fi
if $enable_wall2; then
  kubectl apply -f infrastructure-manager-wall2-pod.yaml
fi
