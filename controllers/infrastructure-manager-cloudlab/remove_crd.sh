#!/bin/bash

if [[ -f "/root/cloudlab-cr.yaml" ]]; then
   kubectl delete -f /root/cloudlab-cr.yaml
fi
