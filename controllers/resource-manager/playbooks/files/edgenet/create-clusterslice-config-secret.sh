#!/bin/bash

kubectl create -n edgenet secret generic clusterslice-config --from-file=config=$HOME/.kube/config
