FROM ubuntu:18.04

WORKDIR /root

# Set a default value for the interactive prompt
ARG DEBIAN_FRONTEND=noninteractive

# install required packages
RUN \
  apt-get update && apt-get install -y python-m2crypto python-dateutil \
                     python-openssl libxmlsec1 xmlsec1 \
                     libxmlsec1-openssl libxmlsec1-dev python-pip

RUN \
  apt-get install -y curl vim jq

# install kubectl
RUN \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# add geni tools
ADD infrastructure-manager-cloudlab/gcf-2.11.tar.gz /root/

# add scripts for infrastructure manager
ADD infrastructure-manager-cloudlab/create.py /root/
ADD infrastructure-manager-cloudlab/release.py /root/
ADD infrastructure-manager-cloudlab/lookup.py /root/
ADD infrastructure-manager-cloudlab/omni_config /root/.gcf/
ADD infrastructure-manager-cloudlab/apply_crd.sh /root/
ADD infrastructure-manager-cloudlab/remove_crd.sh /root/
ADD infrastructure-manager-cloudlab/configure_omni.sh /root/
ADD infrastructure-manager-cloudlab/deploy_testbed_nodes.sh /root/
ADD infrastructure-manager-cloudlab/configure_ssh.sh /root/

# deploy common files for all infrastructure managers
ADD infrastructure-manager-common/start.sh /root/

# prepare geni tools
RUN \
  mv geni-tools-2.11 /usr/local/bin/

RUN \
  ln -s /usr/local/bin/geni-tools-2.11 /usr/local/bin/geni-tools

# install geni-lib
RUN pip install --no-cache-dir geni-lib

# install cloudlab_util
ADD infrastructure-manager-cloudlab/cloudlab_util.py /usr/local/lib/python2.7/dist-packages/geni/
