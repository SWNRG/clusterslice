#!/bin/bash

# executes DHCP server
# should be run in the virtualbox server

# use image prefix, if it exists
if [[ -f "image_prefix" ]]; then
  image_prefix=$(cat image_prefix)
else
  image_prefix="swnrg"
fi

# remove existing clusterslice-dhcp, in the case it exists
docker stop clusterslice-dhcp 2> /dev/null
docker remove clusterslice-dhcp 2> /dev/null

docker run -d --name clusterslice-dhcp --net=host $image_prefix/clusterslice-dhcp
