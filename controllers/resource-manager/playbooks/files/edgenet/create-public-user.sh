#!/bin/bash

# create serviceaccount
kubectl apply -f $HOME/edgenet-public.yaml

# sleep for 3 secs, so service account creation is completed
sleep 3

# create token based user
$HOME/create-token-user.sh
