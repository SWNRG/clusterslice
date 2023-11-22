#!/bin/bash

USERNAME=public
NAMESPACE=uom
CLUSTER=edgenet
SERVICEACCOUNT=edgenet-public
SERVER=IP

# creating .certs folder in home directory
echo "creating .certs folder in home directory"
mkdir $HOME/.certs 2> /dev/null
chmod 700 $HOME/.certs

# creating user token from service account
kubectl create token $SERVICEACCOUNT -n kube-system > $HOME/.certs/$USERNAME-token.txt 2> /dev/null

# Check the exit status
if [ $? -ne 0 ]; then
  # use the approach of older versions of kubernetes, if kubectl create token is not supported
  kubectl get secret -n kube-system edgenet-public-token-$(kubectl get serviceaccount edgenet-public -n kube-system -o jsonpath='{.secrets[0].name}' | cut -d '-' -f 4) -o jsonpath="{.data.token}" | base64 --decode > $HOME/.certs/$USERNAME-token.txt
fi

# creating config file for user
echo "creating config file for user"
kubectl config set-cluster $CLUSTER --server=https://$SERVER:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config set-credentials $USERNAME --token=$(cat $HOME/.certs/$USERNAME-token.txt) --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config set-context $USERNAME-context --namespace=$NAMESPACE --cluster=$CLUSTER --user=$USERNAME --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config use-context $USERNAME-context --kubeconfig=$HOME/.kube/config-$USERNAME

# testing user
echo "testing user"
kubectl get vpnpeers -n default --kubeconfig=$HOME/.kube/config-$USERNAME

