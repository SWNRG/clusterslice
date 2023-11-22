#!/bin/bash

kubectl create secret generic registry-secret \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson -n swn
