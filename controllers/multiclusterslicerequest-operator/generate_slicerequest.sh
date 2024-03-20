#!/bin/bash

echo "apiVersion: \"swn.uom.gr/v1\""
echo "kind: SliceRequest"
echo "metadata:"
echo "  name: $clustername"
echo "  namespace: $user_namespace"

# add owner references, so it is bound to its multiclusterslicerequest that produced it.
# in the case the latter is deleted, the slice follows as well.
echo "  ownerReferences:"
echo "  - apiVersion: \"swn.uom.gr/v1\""
echo "    kind: MultiClusterSliceRequest"
echo "    name: $clusterslice_name"
echo "    uid: $uid"

# slicerequest specification
echo "spec:"
echo "  name: $clustername"
echo "  duration: \"$clusterslice_duration\""
echo "  deploymentstrategy: $deployment_strategy"
echo "  deploymentdomain: $clusterdomain"
echo "  credentials:"
echo "    username: $admin_username"
echo "    password: $admin_password"
echo "  kubernetes:"
if [[ "$kubernetes_type" == null ]]; then
   echo "    kubernetestype: \"\""
else
   echo "    kubernetestype: \"$kubernetes_type\""
fi
if [[ "$kubernetes_version" == null ]]; then
   echo "    kubernetesversion: \"\""
else
   echo "    kubernetesversion: \"$kubernetes_version\""
fi
if [[ "$containerd_version" == null ]]; then
   echo "    containerdversion: \"\""
else
   echo "    containerdversion: \"$containerd_version\""
fi
if [[ "$critools_version" == null ]]; then
   echo "    critoolsversion: \"\""
else
   echo "    critoolsversion: \"$critools_version\""
fi
if [[ "$kubernetes_networkfabric" == null ]]; then
   echo "    networkfabric: \"\""
else
   echo "    networkfabric: \"$kubernetes_networkfabric\""
fi

if [[ "$kubernetes_networkfabricparameters" == null ]]; then
   echo "    networkfabricparameters: \"\""
else
   echo "    networkfabricparameters: \"$kubernetes_networkfabricparameters\""
fi

if [[ "$kubernetes_networkcidr" == null ]]; then
   echo "    networkcidr: \"\""
else
   echo "    networkcidr: \"$kubernetes_networkcidr\""
fi
if [[ "$kubernetes_servicecidr" == null ]]; then
   echo "    servicecidr: \"\""
else
   echo "    servicecidr: \"$kubernetes_servicecidr\""
fi
echo "  infrastructure:"
echo "    masters:"
echo "      count: $infrastructure_masters_count"
echo "      osimage: $infrastructure_masters_os"
echo "      osaccount: $infrastructure_masters_osaccount"
echo "      mastertype: $infrastructure_masters_mastertype"

if [[ $infrastructure_workers_count != "" ]] && [[ $infrastructure_workers_count != "null" ]]; then
   echo "    workers:"
   echo "      count: $infrastructure_workers_count"
   echo "      osimage: $infrastructure_workers_os"
   echo "      osaccount: $infrastructure_workers_osaccount"
   echo "      workertype: $infrastructure_workers_workertype"
fi

# add applications
echo "  applications:"

for arrayindex in ${!app_names[@]};
do
  appname=${app_names[$arrayindex]}
  appversion=${app_versions[$arrayindex]}
  appparameters=${app_parameters[$arrayindex]}
  appsharefile=${app_sharedfiles[$arrayindex]}
  appwaitforfile=${app_waitsforfiles[$arrayindex]}
  appscope=${app_scopes[$arrayindex]}
  appdeployed=${app_deployed[$arrayindex]}

  # replace back space character
  appparameters="${appparameters//[%]/' '}"
  # fix escaping quotes issue
  #appparameters=`echo $appparameters | sed 's/"/\\"/g'`

  echo "      - name: $appname"
  if [[ ! "$appversion" == null ]]; then
    echo "        version: $appversion"
  fi

  if [[ ! "$appparameters" == null ]]; then
    echo "        parameters: \"$appparameters\""
  fi

  if [[ ! "$appsharefile" == null ]]; then
    echo "        sharefile: \"$appsharefile\""
  fi

  if [[ ! "$appwaitforfile" == null ]]; then
    echo "        waitforfile: \"$appwaitforfile\""
  fi

  if [[ ! "$appscope" == null ]]; then
    echo "        scope: \"$appscope\""
  fi

  if [[ ! "$appdeployed" == null ]]; then
    echo "        deployed: $appdeployed"
  fi
done
