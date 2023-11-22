#!/bin/bash

function log_output () {
  local msg=$1
  echo "$msg" >> $output_file
}
