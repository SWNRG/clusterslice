#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: swn.uom.gr/v1
  kind: SliceRequest
  executeHookOnEvent: ["Added", "Modified", "Deleted"]
EOF
else
  slrhookcount=0
  for type in `jq -r '.[].type' ${BINDING_CONTEXT_PATH}`
  do
    watchevent=`jq -r ".[$slrhookcount].watchEvent" ${BINDING_CONTEXT_PATH}`

    if [[ $type == "Synchronization" ]] ; then
      echo "synhronization...."
    fi

    if [[ $type == "Event" ]] ; then
      name=$(jq -r ".[$slrhookcount].object.metadata.name" ${BINDING_CONTEXT_PATH})
      kind=$(jq -r ".[$slrhookcount].object.kind" ${BINDING_CONTEXT_PATH})
      uid=$(jq -r ".[$slrhookcount].object.metadata.uid" ${BINDING_CONTEXT_PATH})
      namespace=$(jq -r ".[$slrhookcount].object.metadata.namespace" ${BINDING_CONTEXT_PATH})

      if [[ $watchevent == "Added" ]] ; then
        echo "${kind}/${name} object is added"

        echo "exporting slice details"
        jq -r ".[$slrhookcount].object.spec" ${BINDING_CONTEXT_PATH} > /tmp/$name-slicerequest.json

        echo "exporting resource details"
        kubectl get cr -o json > /tmp/$name-resources.json

        echo "export uid"
	echo $uid > /tmp/$name-uid

	echo "/opt/clusterslice/prepare_slice.sh $name $namespace"

        # executing main testbed configuration script
        /opt/clusterslice/prepare_slice.sh $name $namespace
      fi

      if [[ $watchevent == "Deleted" ]] ; then
        echo "${kind}/${name} object is deleted"
      fi
    fi
    let slrhookcount=slrhookcount+1
  done

  cp ${BINDING_CONTEXT_PATH} /tmp/debug 2> /dev/null
fi
