#FROM registry.access.redhat.com/ubi8/ubi:latest

#RUN yum update -y && yum install -y stunnel openssh-clients

# Use the Alpine Linux base image
FROM alpine:latest

# Update the package index and install Stunnel and OpenSSH clients
RUN apk update && \
    apk add stunnel openssh-client bash && \
    rm -rf /var/cache/apk/*

# Set the working directory to /root
WORKDIR /root

# Add required files in /root
ADD infrastructure-manager-xcpng/configuration.* /root/
ADD infrastructure-manager-xcpng/create_vm.sh /root/
ADD infrastructure-manager-xcpng/prepare_vm.sh /root/
ADD infrastructure-manager-xcpng/create_snapshot.sh /root/
ADD infrastructure-manager-xcpng/get_vm_uuid.sh /root/
ADD infrastructure-manager-xcpng/check_if_vm_exists_in_server.sh /root/
ADD infrastructure-manager-xcpng/check_if_vm_is_running.sh /root/
ADD infrastructure-manager-xcpng/get_vm_snapshot_uuid.sh /root/
ADD infrastructure-manager-xcpng/revert_to_snapshot.sh /root/
ADD infrastructure-manager-xcpng/remove_vm.sh /root/
ADD infrastructure-manager-xcpng/boot_vm.sh /root/
ADD infrastructure-manager-xcpng/cleanup_vm.sh /root/
ADD infrastructure-manager-xcpng/free_space.sh /root/

# deploy common files for all infrastructure managers
ADD infrastructure-manager-common/readme /root/
ADD infrastructure-manager-common/scripts.txt /root/
ADD infrastructure-manager-common/configure_ssh.sh /root/
ADD infrastructure-manager-common/start.sh /root/
ADD infrastructure-manager-common/deploy_infrastructure_resource.sh /root/
ADD infrastructure-manager-common/functions.sh /root/
ADD infrastructure-manager-common/import_configuration.sh /root/

# Install xapi-xe-1.249.19-1.x86_64.rpm
#ADD infrastructure-manager-xcpng/xapi-xe-1.249.19-1.x86_64.rpm /tmp/
#RUN yum install -y /tmp/xapi-xe-1.249.19-1.x86_64.rpm && rm -f /tmp/xapi-xe-1.249.19-1.x86_64.rpm

# Specify the start script as the CMD
CMD ["/root/start.sh"]
