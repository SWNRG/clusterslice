#!/bin/bash
# enable ssh without password

if (($# == 1)); then
  host=$1
  echo "Enabling ssh without password for host $host"
  cat ~/.ssh/id_rsa.pub | ssh $host 'cat >> .ssh/authorized_keys'
else
  echo "Wrong syntax. You should pass a parameter in the form of user@host."
fi
