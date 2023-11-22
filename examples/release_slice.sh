#!/bin/bash

kubectl -n swn patch slice/$1 --type json --patch='[ { "op": "remove", "path": "/metadata/finalizers" } ]'
