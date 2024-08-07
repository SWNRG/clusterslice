#!/bin/bash

# import configuration, if it is not imported (standalone execution)
if [[ $configuration_is_imported != true ]]; then
  # import basic functions
  source /root/functions.sh

  if [[ $server == "none" ]]; then
     # localhost execution
     configuration_file="/root/configuration"
  else
     configuration_file="/root/configuration.$server"
  fi

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
    log_output "No server configuration file exists, exiting."
    log_output "You should create a configuration file for each"
    log_output "one of the supported cloud servers, in the form"
    log_output "of configuration.server_ip. You can find an"
    log_output "example in file configuration.ip."
    exit 1
  fi
fi
