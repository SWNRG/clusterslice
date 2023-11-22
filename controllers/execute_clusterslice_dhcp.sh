#!/bin/bash

# import configuration
source common_scripts/configuration.sh

# define default image_prefix, if it is not set
if [[ -z "$image_prefix" ]]; then
  image_prefix="swnrg"
fi

# remove existing clusterslice-dhcp, in the case it exists
docker stop clusterslice-dhcp 2> /dev/null > /dev/null
docker remove clusterslice-dhcp 2> /dev/null > /dev/null

echo "Building ClusterSlice DHCP image"
source ./build_controller.sh clusterslice-dhcp

if $enable_DHCP; then
  docker run -d --name clusterslice-dhcp --net=host $image_prefix/clusterslice-dhcp
  echo ""
  echo "ClusterSlice DHCP server is enabled."
else
  echo ""
  echo "ClusterSlice DHCP server is disabled."
fi
