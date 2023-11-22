#!/usr/bin/env bash

source /opt/clusterslice/benchmarking.sh

if [[ $1 == "--config" ]] ; then
  cat <<EOF
configVersion: v1
kubernetes:
- apiVersion: swn.uom.gr/v1
  kind: ComputeResource 
  executeHookOnEvent: ["Modified"]
EOF
else
  crhookcount=0
  for type in `jq -r '.[].type' ${BINDING_CONTEXT_PATH}`
  do
    watchevent=`jq -r ".[$crhookcount].watchEvent" ${BINDING_CONTEXT_PATH}`

    if [[ $type == "Synchronization" ]] ; then
      echo "synhronization...."
    fi

    if [[ $type == "Event" ]] ; then
      name=$(jq -r ".[$crhookcount].object.metadata.name" ${BINDING_CONTEXT_PATH})
      kind=$(jq -r ".[$crhookcount].object.kind" ${BINDING_CONTEXT_PATH})

      if [[ $watchevent == "Modified" ]] ; then
        echo "${kind}/${name} object is modified"

        # check & report status of deployment - only if a node allocation is completed
	status=$(jq -r ".[$crhookcount].object.spec.status" ${BINDING_CONTEXT_PATH})

	# get slice name from updated object's slice field
	clusterslice_name=$(jq -r ".[$crhookcount].object.spec.slice" ${BINDING_CONTEXT_PATH})
	user_namespace=$(jq -r ".[$crhookcount].object.spec.usernamespace" ${BINDING_CONTEXT_PATH})
        apps=$(jq -r ".[$crhookcount].object.spec.apps" ${BINDING_CONTEXT_PATH})


	# do not benchmark updates in apps field
        # be aware that it tracks all updates in cr objects (e.g., for slice name, namespace, apps, etc.)
	if [[ $apps == "" ]]; then
	  benchmark_slice ${clusterslice_name} "" $name $status
        fi

        echo "Modified ${kind}/${name} with status $status clusterslice_name $clusterslice_name"

	# retrieve slice_status
	# if user_namespace & clusterslice_name are passed
	if [[ $user_namespace != ""  ]] && [[ $clusterslice_name != ""  ]]; then
	  #echo "kubectl get sl/clusterslice_name -n user_namespace -o=jsonpath=\"{.spec.status}\""
	  #echo "kubectl get sl/$clusterslice_name -n $user_namespace -o=jsonpath=\"{.spec.status}\""
	  slice_status=`kubectl get sl/$clusterslice_name -n $user_namespace -o=jsonpath="{.spec.status}" 2> /dev/null` # it may produce an error, during slice removal
        fi
	# retrieve updated computeresources object, if a computeresource changes with its slice field set.
	if [ ! -z $clusterslice_name ]; then
	  # do not do that with manually created resources
	  if [ $clusterslice_name != "manual" ]; then
	    kubectl -n swn get computeresources -o json > /tmp/$clusterslice_name-computeresources.json
            if [[ $slice_status != "allocated" ]]; then
               # if the cluster is completed, check application completion
               if [[ $slice_status == "allocating_applications" ]]; then
                  /opt/clusterslice/check_application_completion.sh $clusterslice_name $user_namespace /tmp/$clusterslice_name-computeresources.json
  	       else
                 # if masters are completed and workers have the basic kubernetes tools, it is the time to form the cluster
		 echo "checking resource status against final infrastructure status, which is currently $status"
                 if [[ $status == "kubernetes_master" ]] || [[ $status == "kubernetes_base" ]] || [[ $status == "kubernetes_worker" ]] || [[ $status == "os_completed" ]]; then
                    /opt/clusterslice/check_infrastructure_completion.sh $clusterslice_name $user_namespace /tmp/$clusterslice_name-computeresources.json $status
		 fi
	       fi
	    fi
	  fi
	fi
      fi

    fi
    let crhookcount=crhookcount+1
  done

  cp ${BINDING_CONTEXT_PATH} /tmp/cr-debug 2> /dev/null
fi
