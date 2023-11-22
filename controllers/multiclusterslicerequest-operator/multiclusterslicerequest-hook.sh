#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: swn.uom.gr/v1
  kind: MultiClusterSliceRequest
  executeHookOnEvent: ["Added", "Modified", "Deleted"]
EOF
else
  mcslrhookcount=0
  for type in `jq -r '.[].type' ${BINDING_CONTEXT_PATH}`
  do
    watchevent=`jq -r ".[$mcslrhookcount].watchEvent" ${BINDING_CONTEXT_PATH}`

    if [[ $type == "Synchronization" ]] ; then
      echo "synhronization...."
    fi

    if [[ $type == "Event" ]] ; then
      name=$(jq -r ".[$mcslrhookcount].object.metadata.name" ${BINDING_CONTEXT_PATH})
      kind=$(jq -r ".[$mcslrhookcount].object.kind" ${BINDING_CONTEXT_PATH})
      uid=$(jq -r ".[$mcslrhookcount].object.metadata.uid" ${BINDING_CONTEXT_PATH})
      namespace=$(jq -r ".[$mcslrhookcount].object.metadata.namespace" ${BINDING_CONTEXT_PATH})

      if [[ $watchevent == "Added" ]] ; then
        echo "${kind}/${name} object is added"

        echo "exporting multi-cluster slice request details"
        jq -r ".[$mcslrhookcount].object.spec" ${BINDING_CONTEXT_PATH} > /tmp/$name-mc-slicerequest.json

        echo "export uid"
	echo $uid > /tmp/$name-uid

	echo "/opt/clusterslice/prepare_slicerequests.sh $name $namespace"

        # executing main testbed configuration script
        /opt/clusterslice/prepare_slicerequests.sh $name $namespace
      fi

      if [[ $watchevent == "Deleted" ]] ; then
        echo "${kind}/${name} object is deleted"
      fi
    fi
    let mcslrhookcount=mcslrhookcount+1
  done

  cp ${BINDING_CONTEXT_PATH} /tmp/debug 2> /dev/null
fi
