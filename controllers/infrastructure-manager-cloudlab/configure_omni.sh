#!/bin/bash

# set PATH so it includes geni software if it exists
if [ -d "/usr/local/bin/geni-tools-2.11/src" ] ; then
    PATH="/usr/local/bin/geni-tools-2.11/src:/usr/local/bin/geni-tools-2.11/examples:$PATH"
    export PYTHONPATH="/usr/local/bin/geni-tools-2.11/src:$PYTHONPATH"
fi

# set variables for executable scripts
omni='omni.py'
omni_configure='omni-configure.py'
readyToLogin='readyToLogin.py'
clear_passphrases='clear-passphrases.py'
stitcher='stitcher.py'
remote_execute='remote-execute.py'
addMemberToSliceAndSlivers='addMemberToSliceAndSlivers.py'

# test omni
$omni
