#!/usr/bin/env bash

# this hook is used to initialize benchmarking only
source /opt/clusterslice/benchmarking.sh

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

	benchmark_slice ${name} "requested" "" ""
      fi

      if [[ $watchevent == "Deleted" ]] ; then
        echo "${kind}/${name} object is deleted"
      fi
    fi
    let slrhookcount=slrhookcount+1
  done

  cp ${BINDING_CONTEXT_PATH} /tmp/debug 2> /dev/null
fi
