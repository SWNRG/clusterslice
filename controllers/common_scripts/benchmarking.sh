#!/bin/bash

function benchmark_slice () {
  local slice_name=$1
  local slice_status=$2
  local resource_name=$3
  local resource_status=$4

  current_time=`date +%s%N`
  if [[ $slice_status == "requested" ]]; then
     rm /tmp/${slice_name}_benchmarking.txt 2> /dev/null
     echo $current_time > /tmp/${slice_name}_start_time.txt
     #if [ ! -f /tmp/${slice_name}_start_time.txt ]; then
       #rm /tmp/${slice_name}_benchmarking.txt 2> /dev/null
       #echo $current_time > /tmp/${slice_name}_start_time.txt
     #fi
  fi
 
  # if start_time.txt exists, track measurement
  if [ -f "/tmp/${slice_name}_start_time.txt" ]; then
    start_time=`cat /tmp/${slice_name}_start_time.txt`
    elapsed_time=`expr $current_time - $start_time`
    echo "$slice_name, $slice_status, $resource_name, $resource_status, $elapsed_time" >> /tmp/${slice_name}_benchmarking.txt
  fi
}
