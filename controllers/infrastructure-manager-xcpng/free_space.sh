#!/bin/bash

srs=("coralone_local_storage" "coralone_local_storage_2" "coraltwo_local_storage" "coraltwo_local_storage_2")

uuids=("3c5cb115-15bf-2ab5-5914-91ddfe3fba4a" "07db1682-8f12-3e74-46d4-3591f72b99f4" "6ca3994c-2e47-28c0-3c0a-355ab14e5fa7" "437f46a9-1969-c03b-2664-0f30abd44e96")

sruuid=$1

function get_free_space () {
  result=$(xe sr-list uuid=$sruuid params=physical-utilisation --minimal)
  total=$(xe sr-list uuid=$sruuid params=physical-size --minimal)
  echo "scale=2; $result / $total" | bc | xargs printf "%.2f\n"
}

if [[ -z $sruuid ]]; then
  # no parameter passed, show all SRs
  for arrayindex in ${!srs[@]};
  do
    sr=${srs[$arrayindex]}
    sruuid=${uuids[$arrayindex]}
    echo "$sr $sruuid"
    get_free_space
  done
else
  get_free_space
fi
