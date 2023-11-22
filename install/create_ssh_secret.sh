#!/bin/bash

# store also cloudlab.pem, if it exists
if [[ -f "$HOME/.ssh/cloudlab.pem" ]]; then
  kubectl create secret generic ssh-secret --from-file=cloudlab-pem=$HOME/.ssh/cloudlab.pem --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --from-file=ssh-publickey=$HOME/.ssh/id_rsa.pub -n swn
else
  kubectl create secret generic ssh-secret --from-file=ssh-privatekey=$HOME/.ssh/id_rsa --from-file=ssh-publickey=$HOME/.ssh/id_rsa.pub -n swn
fi
