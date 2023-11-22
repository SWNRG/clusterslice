#!/bin/bash

if [[ -f "/root/cloudlab-cr.yaml" ]]; then
   kubectl apply -f /root/cloudlab-cr.yaml
fi
