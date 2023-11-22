#!/bin/bash
# performing cleaning up of resource
# first parameter is infrastructure operator
# second the cloud server IP
# third the name of resource

operator=$1
cloud_server_ip=$2
resource_name=$3
namespace=$4

# mark resource as free, if it is not, in the meantime, reserved
crstatus=$(kubectl get cr/$resource_name -n $namespace -o=jsonpath="{.spec.status}")
# retrieve resourcetype
resourcetype=$(kubectl get cr/$resource_name -n $namespace -o=jsonpath="{.spec.resourcetype}")

# communicate with the cloud server directly, in the case no operator parameter has been passed
# execute for cloud nodes only
if [[ $resourcetype == "mastervm" ]] || [[ $resourcetype == "workervm" ]]; then
  if [[ $operator == "" ]] || [[ $operator == "none" ]] || [[ $operator == "null" ]]; then
    # remove resource VM
    ssh root@$cloud_server_ip /root/cleanup_vm.sh $cloud_server_ip $resource_name
  else
    # remove VM via the particular operator
    kubectl exec $operator -- /root/cleanup_vm.sh $cloud_server_ip $resource_name
  fi
  if [[ $crstatus != "reserved" ]]; then
    kubectl patch cr/$resource_name --patch "{\"spec\":{\"status\":\"free\"}}" -n $namespace --type merge
    # emptying resource slice field
    kubectl patch cr/$resource_name --patch "{\"spec\":{\"slice\":\"\"}}" -n $namespace --type merge
  fi
else
  # in the case of a test-bed node, should remove the computeresource
  echo "removing resource ${resource_name}, since this is a testbed node."
  kubectl delete cr/${resource_name} -n $namespace
fi
