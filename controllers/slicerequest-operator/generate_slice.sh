#!/bin/bash

echo "apiVersion: \"swn.uom.gr/v1\""
echo "kind: Slice"
echo "metadata:"
echo "  name: $clusterslice_name"
echo "  namespace: $user_namespace"

# add finalizer, so slice deletion is suspended until the finalizer is removed.
# we use this strategy to make sure that computeresources are removed with the
# slice removal.
# the finalizer can be removed with a command of this type:
# kubectl -n swn patch slice/clusterslice --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]'
# after that, the object deletion is completed.

echo "  finalizers:"
echo "  - kubernetes/removecrfirst"

# add owner references, so it is bound to its slicerequest that produced it.
# in the case the latter is deleted, the slice follows as well.
echo "  ownerReferences:"
echo "  - apiVersion: \"swn.uom.gr/v1\""
echo "    kind: SliceRequest"
echo "    name: $clusterslice_name"
echo "    uid: $uid"

# slice specification
echo "spec:"
echo "  name: $clusterslice_name"
echo "  duration: \"$clusterslice_duration\""
echo "  credentials:"
echo "    username: $admin_username"
echo "    password: $admin_password"
echo "  kubernetes:"
echo "    kubernetestype: \"$kubernetes_type\""
echo "    kubernetesversion: \"$kubernetes_version\""
echo "    containerdversion: \"$containerd_version\""
echo "    critoolsversion: \"$critools_version\""
echo "    networkfabric: \"$kubernetes_networkfabric\""

# replace back space character
kubernetes_networkfabricparameters="${kubernetes_networkfabricparameters//[%]/' '}"
if [[ ! "$kubernetes_networkfabricparameters" == null ]]; then
  echo "    networkfabricparameters: \"$kubernetes_networkfabricparameters\""
else
  echo "    networkfabricparameters: \"none\""
fi

echo "    networkcidr: \"$kubernetes_networkcidr\""
echo "    servicecidr: \"$kubernetes_servicecidr\""
echo "  infrastructure:"
echo "    masters: \"0/$infrastructure_masters_count\""
echo "    workers: \"0/$infrastructure_workers_count\""
echo "  deployment:"
echo "    master:"

# add master nodes
for arrayindex in ${!slice_masters_names[@]};
do
  node_name=${slice_masters_names[$arrayindex]}
  node_type=${slice_masters_types[$arrayindex]}
  node_ip=${slice_masters_ips[$arrayindex]}
  node_mac=${slice_masters_macs[$arrayindex]}
  node_secondaryip=${slice_masters_secondary_ips[$arrayindex]}
  node_secondarymac=${slice_masters_secondary_macs[$arrayindex]}
  node_server_ip=${slice_masters_server_ips[$arrayindex]}
  node_server_name=${slice_masters_server_names[$arrayindex]}
  node_server_operator=${slice_masters_server_operators[$arrayindex]}

  echo "      - name: $node_name"
  echo "        resourcetype: $node_type"
  echo "        osimage: \"$infrastructure_masters_osimage\""
  echo "        osaccount: \"$infrastructure_masters_osaccount\""
  echo "        ip: $node_ip"
  echo "        mac: $node_mac"
  echo "        secondaryip: $node_secondaryip"
  echo "        secondarymac: $node_secondarymac"
  echo "        serverip: $node_server_ip"
  echo "        servername: $node_server_name"
  echo "        serveroperator: $node_server_operator"
done

echo "    worker:"

# add worker nodes                                                              
for arrayindex in ${!slice_workers_hosts[@]};
do
  node_name=${slice_workers_hosts[$arrayindex]}
  node_type=${slice_workers_types[$arrayindex]}
  node_ip=${slice_workers_ips[$arrayindex]}
  node_mac=${slice_workers_macs[$arrayindex]}
  node_secondaryip=${slice_workers_secondary_ips[$arrayindex]}
  node_secondarymac=${slice_workers_secondary_macs[$arrayindex]}
  node_server_ip=${slice_workers_server_ips[$arrayindex]}
  node_server_name=${slice_workers_server_names[$arrayindex]}
  node_server_operator=${slice_workers_server_operators[$arrayindex]}

  echo "      - name: $node_name"
  echo "        resourcetype: $node_type"
  echo "        osimage: \"$infrastructure_workers_osimage\""
  echo "        osaccount: \"$infrastructure_workers_osaccount\""
  echo "        ip: $node_ip"
  echo "        mac: $node_mac"
  echo "        secondaryip: $node_secondaryip"
  echo "        secondarymac: $node_secondarymac"
  echo "        serverip: $node_server_ip"
  echo "        servername: $node_server_name"
  echo "        serveroperator: $node_server_operator"
done

# add applications
echo "  applications:"

for arrayindex in ${!app_names[@]};
do
  appname=${app_names[$arrayindex]}
  appversion=${app_versions[$arrayindex]}
  appparameters=${app_parameters[$arrayindex]}
  appscope=${app_scopes[$arrayindex]}
  appsharefile=${app_sharedfiles[$arrayindex]}
  appwaitforfile=${app_waitsforfiles[$arrayindex]}
  appdeployed=${app_deployed[$arrayindex]}

  # replace back space character
  appparameters="${appparameters//[%]/' '}"
  # fix escaping quotes issue
  #appparameters=`echo $appparameters | sed 's/"/\\"/g'`

  echo "      - name: $appname"
  if [[ ! "$appversion" == null ]]; then
    echo "        version: $appversion"
  else
    echo "        version: \"none\""
  fi
  if [[ ! "$appparameters" == null ]]; then
    echo "        parameters: \"$appparameters\""
  else
    echo "        parameters: \"none\""
  fi

  if [[ ! "$appsharefile" == null ]]; then
    echo "        sharefile: \"$appsharefile\""
  else
    echo "        sharefile: \"none\""
  fi

  if [[ ! "$appwaitforfile" == null ]]; then
    echo "        waitforfile: \"$appwaitforfile\""
  else
    echo "        waitforfile: \"none\""
  fi

  echo "        scope: \"$appscope\""
  echo "        deployed: $appdeployed"
done
