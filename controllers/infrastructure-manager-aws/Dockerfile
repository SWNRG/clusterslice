# Use the Alpine Linux base image
FROM alpine:latest

# Update the package index and install Stunnel and OpenSSH clients
RUN apk update && \
    apk add stunnel openssh-client bash && \
    rm -rf /var/cache/apk/*

# Set the working directory to /root
WORKDIR /root

# Add required files in /root
ADD infrastructure-manager-aws/configuration.* /root/
ADD infrastructure-manager-aws/hostname-* /root/
ADD infrastructure-manager-aws/create_vm.sh /root/
ADD infrastructure-manager-aws/prepare_vm.sh /root/
ADD infrastructure-manager-aws/create_snapshot.sh /root/
ADD infrastructure-manager-aws/get_vm_uuid.sh /root/
ADD infrastructure-manager-aws/check_if_vm_exists_in_server.sh /root/
ADD infrastructure-manager-aws/check_if_vm_is_running.sh /root/
ADD infrastructure-manager-aws/get_vm_snapshot_uuid.sh /root/
ADD infrastructure-manager-aws/revert_to_snapshot.sh /root/
ADD infrastructure-manager-aws/remove_vm.sh /root/
ADD infrastructure-manager-aws/boot_vm.sh /root/
ADD infrastructure-manager-aws/cleanup_vm.sh /root/

# deploy common files for all infrastructure managers
ADD infrastructure-manager-common/scripts.txt /root/
ADD infrastructure-manager-common/configure_ssh.sh /root/
ADD infrastructure-manager-common/start.sh /root/
ADD infrastructure-manager-common/deploy_infrastructure_resource.sh /root/
ADD infrastructure-manager-common/functions.sh /root/
ADD infrastructure-manager-common/import_configuration.sh /root/

# Specify the start script as the CMD
CMD ["/root/start.sh"]
