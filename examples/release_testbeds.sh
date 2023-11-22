#!/bin/bash

kubectl exec -ti infrastructure-manager-cloudlab -- /root/release.py
kubectl exec -ti infrastructure-manager-apt -- /root/release.py
kubectl exec -ti infrastructure-manager-wisconsin -- /root/release.py
kubectl exec -ti infrastructure-manager-wall2 -- /root/release.py
