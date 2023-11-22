FROM ubuntu:22.04

RUN apt-get update

# install ansible
RUN \
  apt-get install -y software-properties-common && \
  apt-get update && \
  add-apt-repository -y ppa:ansible/ansible && \
  apt-get update && \
  apt-get install -y ansible

# install ssh, curl and vim
RUN \
  apt-get install -y ssh curl vim jq

# install kubectl
RUN \
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# add clusterslice testbed files
ADD resource-manager/*.sh /opt/clusterslice/

# create playbooks directory
RUN \
  mkdir /opt/clusterslice/ansible/ /opt/clusterslice/playbooks/ /opt/clusterslice/playbooks/files/ /opt/clusterslice/playbooks/files/teaching-examples/ /opt/clusterslice/playbooks/files/argo/ /opt/clusterslice/playbooks/files/toolkit/

# create shared directory
RUN \
  mkdir /opt/clusterslice/shared/

ADD resource-manager/playbooks/*.yaml /opt/clusterslice/playbooks/
ADD resource-manager/playbooks/*.template /opt/clusterslice/playbooks/
ADD resource-manager/playbooks/files/* /opt/clusterslice/playbooks/files/ 
ADD resource-manager/playbooks/files/teaching-examples/* /opt/clusterslice/playbooks/files/teaching-examples/
ADD resource-manager/playbooks/files/argo/* /opt/clusterslice/playbooks/files/argo/
ADD resource-manager/playbooks/files/toolkit/* /opt/clusterslice/playbooks/files/toolkit/
ADD resource-manager/playbooks/files/benchmarks/* /opt/clusterslice/playbooks/files/benchmarks/
ADD resource-manager/playbooks/files/edgenet/* /opt/clusterslice/playbooks/files/edgenet/
ADD resource-manager/playbooks/files/l2sm/* /opt/clusterslice/playbooks/files/l2sm/
ADD resource-manager/ansible/hosts /opt/clusterslice/ansible/ 
ADD common_scripts/configuration.sh /opt/clusterslice/
ADD common_scripts/basic_functions.sh /opt/clusterslice/
ADD common_scripts/benchmarking.sh /opt/clusterslice/
