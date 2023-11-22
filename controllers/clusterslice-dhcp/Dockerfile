# Use a lightweight Linux distribution as the base image
FROM alpine:latest

# Install necessary packages
RUN apk update && \
    apk add --no-cache dhcp openrc

# Copy the DHCP server configuration file
COPY clusterslice-dhcp/dhcpd.conf /etc/dhcp/dhcpd.conf

# Expose the DHCP port
EXPOSE 67/udp

# Create the lease database directory
RUN mkdir -p /var/lib/dhcp

RUN touch /var/lib/dhcp/dhcpd.leases

# Start the DHCP server when the container is run
CMD ["dhcpd", "-f", "-d", "--no-pid", "-lf", "/var/lib/dhcp/dhcpd.leases"]

