#!/bin/bash

# release existing slice, if it exists (ignore errors)
#release.py 2> /dev/null

# deploy testbed nodes
/root/create.py $@

# update computeresources via kubectl
/root/apply_crd.sh
