#!/bin/bash

# configure ssh keys
mkdir /root/.ssh 2> /dev/null
cp /etc/ssh/ssh-privatekey /root/.ssh/id_rsa 2> /dev/null
cp /etc/ssh/ssh-publickey /root/.ssh/id_rsa.pub 2> /dev/null
cp /etc/ssh/id_rsa /root/.ssh/id_rsa 2> /dev/null
cp /etc/ssh/id_rsa.pub /root/.ssh/id_rsa.pub 2> /dev/null
