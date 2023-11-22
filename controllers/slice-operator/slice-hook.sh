#!/usr/bin/env bash

source /opt/clusterslice/benchmarking.sh

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: swn.uom.gr/v1
  kind: Slice
  executeHookOnEvent: ["Added", "Modified", "Deleted"]
EOF
else
  slhookcount=0
  for type in `jq -r '.[].type' ${BINDING_CONTEXT_PATH}`
  do
    watchevent=`jq -r ".[$slhookcount].watchEvent" ${BINDING_CONTEXT_PATH}`

    if [[ $type == "Synchronization" ]] ; then
      echo "synhronization...."
    fi

    if [[ $type == "Event" ]] ; then
      name=$(jq -r ".[$slhookcount].object.metadata.name" ${BINDING_CONTEXT_PATH})
      kind=$(jq -r ".[$slhookcount].object.kind" ${BINDING_CONTEXT_PATH})
      uid=$(jq -r ".[$slhookcount].object.metadata.uid" ${BINDING_CONTEXT_PATH})
      namespace=$(jq -r ".[$slhookcount].object.metadata.namespace" ${BINDING_CONTEXT_PATH})

      if [[ $watchevent == "Added" ]] ; then
        echo "${kind}/${name} object is added"

        benchmark_slice ${name} "added" "" ""

        echo "exporting slice details"
        jq -r ".[$slhookcount].object.spec" ${BINDING_CONTEXT_PATH} > /tmp/$name-slice.json
        #echo "exporting resource details"
        #kubectl get cr -o json > /tmp/$name-resources.json

	echo "exporting slice uid"
	echo $uid > /tmp/$name-uid

	echo "deploying slice"
	/opt/clusterslice/deploy_slice.sh $name $namespace
      fi

      if [[ $watchevent == "Modified" ]] ; then
        echo "${kind}/${name} object is modifed"

	benchmark_slice ${name} "modified" "" ""

	# check if it is a modification that relates to a blocked deletion, i.e., added deletionTimestamp
        deletionTimestamp=`jq -r ".[$slhookcount].object.metadata.deletionTimestamp" ${BINDING_CONTEXT_PATH}`

        #echo "deletionTimestamp is $deletionTimestamp"

        if [[ ! "$deletionTimestamp" == null ]]; then

          echo "object is marked for deletion"

          # should remove all computeresources assigned to the slice
          echo "Removing computeresources assigned to the slice"

          # iterate through all masters
	  nodecount=0
	  # check if master nodes exist
	  masters_check=`jq -r ".[$slhookcount].object.spec.deployment.master" ${BINDING_CONTEXT_PATH}`
          if [[ ! "$masters_check" == null ]]; then
            for cr_name in `jq -r ".[$slhookcount].object.spec.deployment.master[].name" ${BINDING_CONTEXT_PATH}`
            do
              echo "updating resource $cr_name status to 'free'"
              kubectl patch cr/$cr_name --patch "{\"spec\":{\"status\":\"free\"}}" -n swn --type merge
              echo "emptying resource $cr_name slice"
	      kubectl patch cr/$cr_name --patch "{\"spec\":{\"slice\":\"\"}}" -n swn --type merge
              echo "emptying resource $cr_name apps"
              kubectl patch cr/$cr_name --patch "{\"spec\":{\"apps\":\"\"}}" -n swn --type merge
              echo "emptying resource $cr_name usernamespace"
	      kubectl patch cr/$cr_name --patch "{\"spec\":{\"usernamespace\":\"\"}}" -n swn --type merge
              let nodecount=nodecount+1
	    done
	  fi

          # iterate through all workers
          nodecount=0
          # check if worker nodes exist
	  workers_check=`jq -r ".[$slhookcount].object.spec.deployment.worker" ${BINDING_CONTEXT_PATH}`
          if [[ ! "$workers_check" == null ]]; then
            for cr_name in `jq -r ".[$slhookcount].object.spec.deployment.worker[].name" ${BINDING_CONTEXT_PATH}`
            do
              echo "updating resource $cr_name status to 'free'"
              kubectl patch cr/$cr_name --patch "{\"spec\":{\"status\":\"free\"}}" -n swn --type merge
              echo "emptying resource $cr_name slice"
              kubectl patch cr/$cr_name --patch "{\"spec\":{\"slice\":\"\"}}" -n swn --type merge
              echo "emptying resource $cr_name apps"
	      kubectl patch cr/$cr_name --patch "{\"spec\":{\"apps\":\"\"}}" -n swn --type merge
              let nodecount=nodecount+1
            done
	  fi

	  # and now, unblock the slice deletion
          kubectl -n $namespace patch slice/$name --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]'
	fi
      fi

      if [[ $watchevent == "Deleted" ]] ; then
        echo "${kind}/${name} object is deleted"
        benchmark_slice ${name} "deleted" "" ""
      fi
    fi
    let slhookcount=slhookcount+1
  done

  cp ${BINDING_CONTEXT_PATH} /tmp/sl-debug 2> /dev/null
fi
