# builds a fresh install-clusterslice.yaml file.
echo "Building a fresh install-clusterslice.yaml file"
cat ../security/create-namespace.yaml ../crds/computeresources-crd.yaml  ../crds/slice-crd.yaml  ../crds/slicerequest-crd.yaml ../crds/multiclusterslicerequest-crd.yaml ../security/clusterslice-rbac-rules.yaml ../security/clusterslice-allusers-rbac-rules.yaml ../controllers/slicerequest-operator-pod.yaml ../controllers/slice-operator-pod.yaml > install-clusterslice.yaml

# copying necessary scripts
echo "Copying necessary scripts"
cp ../security/create_private_registry_secret.sh .
cp ../security/create_ssh_secret.sh .
