FROM registry.access.redhat.com/ubi8/ubi:latest

RUN yum update -y && yum install -y openssh-clients

# Set the working directory to /root
WORKDIR /root

# Add required files in /root
ADD infrastructure-manager-virtualbox/configuration.* /root/
ADD infrastructure-manager-virtualbox/create_vm.sh /root/
ADD infrastructure-manager-virtualbox/prepare_vm.sh /root/
ADD infrastructure-manager-virtualbox/create_snapshot.sh /root/
ADD infrastructure-manager-virtualbox/get_vm_uuid.sh /root/
ADD infrastructure-manager-virtualbox/check_if_vm_exists_in_server.sh /root/
ADD infrastructure-manager-virtualbox/check_if_vm_is_running.sh /root/
ADD infrastructure-manager-virtualbox/get_vm_snapshot_uuid.sh /root/
ADD infrastructure-manager-virtualbox/revert_to_snapshot.sh /root/
ADD infrastructure-manager-virtualbox/remove_vm.sh /root/
ADD infrastructure-manager-virtualbox/cleanup_vm.sh /root/
ADD infrastructure-manager-virtualbox/boot_vm.sh /root/

# deploy common files for all infrastructure managers
ADD infrastructure-manager-common/readme /root/
ADD infrastructure-manager-common/scripts.txt /root/
ADD infrastructure-manager-common/configure_ssh.sh /root/
ADD infrastructure-manager-common/start.sh /root/
ADD infrastructure-manager-common/deploy_infrastructure_resource.sh /root/
ADD infrastructure-manager-common/functions.sh /root/
ADD infrastructure-manager-common/import_configuration.sh /root/

# Specify the start script as the CMD
CMD ["/root/start.sh"]
