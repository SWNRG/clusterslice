#!/bin/bash

USERNAME=TBA
NAMESPACE=TBA
CLUSTER=TBA
SERVER=TBA
ROLE=TBA

# creating namespace if it does not exist
echo "creating namespace"
kubectl create namespace $NAMESPACE 2> /dev/null

# creating and moving to .certs folder in home directory
echo "creating .certs folder in home directory"
mkdir $HOME/.certs 2> /dev/null

# creating private key for user
echo "creating private key for user"
openssl genrsa -out $HOME/.certs/$USERNAME.key 2048

# create a certificate sign request
echo "creating certificate sign request"
openssl req -new -key $HOME/.certs/$USERNAME.key -out $HOME/.certs/$USERNAME.csr -subj "/CN=$USERNAME/O=$NAMESPACE"
# create a clean sign request
cat $HOME/.certs/$USERNAME.csr | base64 | tr -d "\n" > $HOME/.certs/$USERNAME-clean.csr

# removing existing csr object if it exists
kubectl delete csr/$USERNAME 2> /dev/null

# create CertificateSigningRequest object
cat > $HOME/.certs/$USERNAME-request.yaml << EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
 name: $USERNAME
spec:
 request: $(cat $HOME/.certs/$USERNAME-clean.csr)
 signerName: kubernetes.io/kube-apiserver-client
 expirationSeconds: 31536000 # 1 year
 usages:
 - client auth
EOF

# applying sign request
kubectl apply -f $HOME/.certs/$USERNAME-request.yaml

# approving sign request
echo "approving sign request"
kubectl certificate approve $USERNAME

# exporting approved user certification
echo "exporting approved user certification"
kubectl get csr $USERNAME -o jsonpath='{.status.certificate}'| base64 -d > $HOME/.certs/$USERNAME.crt

# creating and applying rolebinding
echo "creating and applying rolebinding"
cat > $HOME/.certs/$USERNAME-rolebinding.yaml << EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: $USERNAME-$ROLE
  namespace: default
subjects:
  - kind: User
    name: $USERNAME
roleRef:
  kind: ClusterRole
  name: $ROLE
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f $HOME/.certs/$USERNAME-rolebinding.yaml

# creating config file for user
echo "creating config file for user"
kubectl config set-cluster $CLUSTER --server=https://$SERVER:6443 --certificate-authority=/etc/kubernetes/pki/ca.crt --embed-certs=true --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config set-credentials $USERNAME --client-certificate=$HOME/.certs/$USERNAME.crt  --client-key=$HOME/.certs/$USERNAME.key --embed-certs=true --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config set-context $USERNAME-context --namespace=$NAMESPACE --cluster=$CLUSTER --user=$USERNAME --kubeconfig=$HOME/.kube/config-$USERNAME
kubectl config use-context $USERNAME-context --kubeconfig=$HOME/.kube/config-$USERNAME

# testing user
echo "testing user"
kubectl get tenants -n default --kubeconfig=$HOME/.kube/config-$USERNAME
