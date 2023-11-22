#!/bin/bash
# input parameter is controller name

# Validate input parameters
if [ $# -ne 1 ]; then
  echo "Usage: $0 <controller_name>"
  exit 1
fi
controller_name=$1

# build and upload controller

docker build -t "${image_prefix}/${controller_name}" -f ${controller_name}/Dockerfile .
if $push_images; then
  docker push ${image_prefix}/${controller_name}
fi
