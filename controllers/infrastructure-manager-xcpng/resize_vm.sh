#!/bin/bash

# resize_vm configuration:
hd_size=70GiB
memory_size=16GiB
vcpus=8

# Check if a parameter is passed; if not, exit with an error message
if [ -z "$1" ]; then
  echo "Error: No parameter provided. Please provide a VM name."
  exit 1
fi

vm_name=$1

# Check running state of VM
running_state=$(xe vm-list name-label=$vm_name | grep power-state | awk '{print $4}')

if [[ "$running_state" == "running" ]]; then
  echo "You should shutdown VM, before resizing it."
  exit 1
fi

exit 0

vm_uuid=$(xe vm-list name-label=$vm_name | grep "uuid ( RO)" | tail -1 | awk '{print $5}')

echo "Determining the uuid of VM $vm_name: $vm_uuid "

echo ""
echo "1) Resizing disk of VM $vm_name."
disk_uuid=$(xe vm-disk-list vm=kubem2 | grep "uuid ( RO)" | tail -1 | awk '{print $5}')
echo "Determining disk uuid of VM $vm_name: $disk_uuid."
xe vdi-resize uuid=$disk_uuid disk-size=$hd_size
echo "Disk resized to $hd_size"
echo "You should manually complete disk resizing when connected to the VM:"
echo "sudo cfdisk /dev/xvda"
echo "sudo pvresize /dev/xvda3"
echo "sudo lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv"
echo ""
echo "2) Resizing memory of VM $vm_name."
xe vm-memory-limits-set uuid=$vm_uuid static-min=$memory_size dynamic-min=$memory_size dynamic-max=$memory_size static-max=$memory_size
echo ""
echo "3) Resizing CPU of VM $vm_name."
xe vm-param-set uuid=$vm_uuid VCPUs-max=$vcpus
xe vm-param-set uuid=$vm_uuid VCPUs-at-startup=$vcpus
