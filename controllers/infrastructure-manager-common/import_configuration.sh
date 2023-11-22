#!/bin/bash

# import configuration, if it is not imported (standalone execution)
if [[ $configuration_is_imported != true ]]; then
  # import basic functions
  source /root/functions.sh
  configuration_file="/root/configuration.$server"

  # define output file
  output_file="/tmp/output-${vm}.txt"
  # clear output file, ignore error if it does not exist.
  rm $output_file 2> /dev/null

  if [[ -f $configuration_file ]]; then
    # import configuration file
    source $configuration_file

    # set a variable that configuration is imported
    configuration_is_imported=true
  else
    log_output "no server configuration file exists, exiting."
    exit 1
  fi
fi
