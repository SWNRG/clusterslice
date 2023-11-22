<p align="center">
    <img src="../clusterslice-logo.svg" alt="Welcome to ClusterSlice" width="400">
</p>

# Installation and Administration Instructions

## Table of Contents

- [Installing Prerequisites](#installing-prerequisites)
- [Using a Private Repository](#using-a-private-repository)
- [Configuring ClusterSlice](#configuring-clusterslice)
- [Test-bed Compute Resources](#test-bed-compute-resources)
- [Virtualization Systems](#virtualization-systems)
- [Custom Resources and Operators](#custom-resources-and-operators)
- [New Test-bed Users](#new-test-bed-users)
- [Missing Features](#missing-features)

## Installing Prerequisites

The ClusterSlice software requires a fresh Kubernetes installation as well as docker engine and ansible. It provides a containarized version of ISC DHCP server, but one may use a local version. You should first clone the ClusterSlice repository and move to the install directory:

```console
user@boss:~$ git clone https://github.com/SWNRG/clusterslice

user@boss:~$ cd clusterslice/install
```

We provide quick installation instructions for ansible, vanilla Kubernetes and Docker, for Ubuntu Linux. 

### Ansible

Install ansible:

```console
user@boss:~/clusterslice/install$ sudo apt install software-properties-common

user@boss:~/clusterslice/install$ sudo add-apt-repository --yes --update ppa:ansible/ansible

user@boss:~/clusterslice/install$ sudo apt install ansible
```

### Kubernetes

Install vanilla kubernetes from vanilla-kubernetes directory:

In master node:

```console
user@boss:~/clusterslice/install/vanilla-kubernetes$ ansible-playbook install_kubernetes_base.yaml 

user@boss:~/clusterslice/install/vanilla-kubernetes$ ansible-playbook install_kubernetes_master.yaml
```

In worker nodes:

```console
user@boss:~/clusterslice/install/vanilla-kubernetes$ ansible-playbook install_kubernetes_base.yaml
```

Finally, retrieve the cluster join command that appears in the master host (file `kubernetes_join_command`) and execute it in all worker nodes.

### Docker Engine

Install docker in all nodes. There is no need to add the docker repository, because it was added with the kubernetes installation.

```console
user@boss:~$ sudo apt-get install docker-ce docker-ce-cli

user@boss:~$ sudo usermod -aG docker user
```

## Using a Private Repository

A private image repository may be optionally enabled. In that case, one should follow the steps briefly described below.

1) Add the self-signed certificate from private repository to both masters and workers at `/usr/local/share/ca-certificates/domain.crt` and execute `update-ca-certificates`. You should also run the following commands:

```console
user@boss:~$ sudo mkdir -p /etc/docker/certs.d/private_repository:port

user@boss:~$ sudo cp domain.crt /etc/docker/certs.d/private_repository:port/ca.crt
```

This is an example command that produces a self-signed certificate on behalf of the private repository:

```console
user@repository-server:~$ openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout docker_reg_certs/domain.key -out docker_reg_certs/domain.crt -subj "/CN=private_repository" -addext "subjectAltName=DNS:private_repository"
```

You can verify the installed certificate with the following command:

```console
user@repository-server:~$ openssl s_client -connect private_repository:port -showcerts
```

2) Login to the private repository with docker:

```console
user@boss:~$ docker login private_repository_address
```

This command stores the access credentials in `$HOME/.docker/config.json`

3) Create a secret kubernetes object by executing the following script:

```console
user@boss:~/clusterslice/install$ ./create_private_registry_secret.sh
```

The above three steps allow kubernetes and docker engine to access the private repository. If it does not work (e.g., the pods return a ImagePullBackOff status), we suggest to reboot all cluster nodes.

## Configuring ClusterSlice

The next step is to update the main ClusterSlice configuration file `clusterslice/controllers/common_scripts/configuration.sh`. You should execute the following commands:

```console
user@boss:~/clusterslice/controllers/common_scripts$ cp configuration-example.sh configuration.sh
```

Now, edit the `configuration.sh` file and fix at least the following parameters:

```console
# define test-bed gateway
gateway="x.y.z.w"

# enable infrastructure managers
enable_virtualbox=false
enable_xcpng=false
enable_cloudlab=false

# enable DHCP server
enable_DHCP=true

# image prefix (i.e., define it in the case of a private image repository)
image_prefix="private_repository:port"

# define if containers are being pushed in the repository or not (enable it in the case of a private repository)
push_images=true
```

At this point, we support VirtualBox, XCP-NG and CloudLab resources, so enable the infrastructure managers at your will.

## Test-bed Compute Resources

The test-bed compute resources should be configured in two places, in the configuration file of DHCP server and a ComputeResources manifest. We should first clone and edit relevant example configuration files.

```console
user@boss:~/clusterslice/controllers/clusterslice-dhcp$ cp dhcpd.conf.example dhcpd.conf
``` 

Now edit `dhcpd.conf` and specify the IP and MAC addresses of all test-bed nodes, as well as the test-bed subnet configuration and DNS servers. The DHCP server runs in a docker container that should be manually executed:

```console
user@boss:~/clusterslice/controllers$ ./execute_clusterslice_dhcp.sh
```
Make sure that it works, e.g., with `docker container ls` or `docker logs` commands.

An equivalent process should be followed for the ComputeResources manifest:

```console
user@boss:~/clusterslice/install$ cp computeresources-example.yaml computeresources.yaml
```

The cloud server details should be configured, as well as the parameters of all test-bed nodes. One can also see the multi-clustering example [clusterslice/install/computeresources-multi-cluster-example.yaml](computeresources-multi-cluster-example.yaml).

## Virtualization Systems

In each one of the enabled infrastructure managers residing at the [clusterslice/controllers](../controllers) directory, the example configuration scripts should be cloned and edited, in a similar manner. Please note that the configuration script names should be in the form of `configuration.serverip`.

At this point, you should create a VM template:

* Create a clean Linux VM installation. We suggest to use Ubuntu 22.04 for maximum compatibility.
* Add a user with root privileges named `user`.
* Enable `sudo` without a password for user named `user`. You can run the following command: `sudo visudo` and then add at the end of the file: `user            ALL = (ALL) NOPASSWD: ALL`
* Create ssh keys in the ClusterSlice master node with the `ssh-keygen` command and share them with both cloud server and VM, using the command `./ssh_without_password.sh username@server`. Make sure that you can access them without a password.
* Export the VM and place it in the cloud server directory, as indicated in the infrastructure manager's configuration file.

Finally, share the ssh keys with operators through a kubernetes secret object (i.e., allows clusterslice containers to access the keys):

```console
user@boss:~/clusterslice/install$ ./create_ssh_secret.sh
```

## Custom Resources and Operators

We now install the Custom Resources and Operators of ClusterSlice with the following commands:

```console
user@boss:~/clusterslice/controllers$ ./update_operators.sh
```

The images of the Operators have been created and optionally uploaded to the private repository.

```console
user@boss:~/clusterslice/install$ ./build_fresh_install-clusterslice-yaml.sh

user@boss:~/clusterslice/install$ kubectl apply -f install-clusterslice.yaml
```

All ClusterSlice Custom Resources have been applied, including the security manifests. You can check if the operators and requested infrastructure managers are running with the following command:

```console
user@boss:~/clusterslice/install$ kubectl get pods -n swn
```

Now it is time to apply the `ComputeResources`:

```console
user@boss:~/clusterslice/install$ kubectl apply -f computeresources.yaml
```

You can check their status:

```console
user@boss:~/clusterslice/install$ kubectl get computeresources -n swn
```

## New Test-bed Users 

Start by generating a new namespace for the user (with the same name with his/her username):

```console
user@boss:~$ kubectl create namespace username
```

The new users have been given access, as defined in the `Role` and `RoleBinding` objects defined in `security/clusterslice-user-rbac-rules.yaml`. Create a new YAML file based on `security/clusterslice-user-rbac-rules.yaml` and execute `kubectl apply -f clusterslice-newuser-rbac-rules.yaml`. 

The new username should also be added in `clusterslice-allusers-rbac-rules.yaml` like the existing ones. Then execute `kubectl apply -f clusterslice-allusers-rbac-rules.yaml`.

Create a private key for the user (we use the example username lefteris).

```console
user@boss:~$ openssl genrsa -out lefteris.key 2048
```

Create a certificate sign request using this private key. You specify the username and group in the subj section (CN is for username and O for the group):

```console
user@boss:~$ openssl req -new -key lefteris.key -out lefteris.csr -subj "/CN=lefteris/O=uom"
```

Generate a final certificate, e.g., for 500 days (execute this as root):

```console
user@boss:~$ sudo openssl x509 -req -in lefteris.csr -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out lefteris.crt -days 500
```

Save .crt and .key files in `$HOME/.certs/`

Add a new context with the new credential for the kubernetes cluster.

```console
user@boss:~$ kubectl config set-cluster kubernetes --server=https://ServerIP:6443 --certificate-authority=/etc/kubernetes/pki/ca.key --embed-certs=true --kubeconfig=$HOME/.kube/config

user@boss:~$ kubectl config set-credentials lefteris --client-certificate=$HOME/.certs/lefteris.crt  --client-key=$HOME/.certs/lefteris.key --embed-certs=true --kubeconfig=$HOME/.kube/config

user@boss:~$ kubectl config set-context lefteris-context --namespace=swn --cluster=kubernetes --user=lefteris
```

Alternatively, a config file like the one described below should be given to the user. He/she should add it to folder `$HOME/.kube` (as well as the `user.key` and `user.crt` files in `$HOME/.certs`):

Example config file:

```YAML
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: <ADD FROM /etc/kubernetes/pki/ca.crt>
    server: https://ServerIP:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    namespace: lefteris
    user: lefteris
  name: lefteris-context@kubernetes
current-context: lefteris-context@kubernetes
kind: Config
preferences: {}
users:
- name: lefteris
  user:
    client-certificate: /home/user/.certs/lefteris.crt
    client-key: /home/user/.certs/lefteris.key
```

The key and certificate could also be embeded in the config file.

The user is now able to execute a number of test-bed control commands. Some examples follow.

1) Apply a new slice request:

```console
lefteris@boss:~/clusterslice/examples$ kubectl apply -f slicerequest.yaml
```

2) Check the slice request and its status:

```console
lefteris@boss:~/clusterslice/examples$ kubectl get slicerequests
```

3) Check the to be allocated / allocated slices:

```console
lefteris@boss:~/clusterslice/examples$ kubectl get slices
```

4) Check the allocated test-bed resources (testbed-wide kubernetes resources belong in the swn namespace):

```console
lefteris@boss:~/clusterslice/examples$ kubectl get computeresources -n swn
```

## Missing features

* Debugging, debugging, debugging.
* Synchronizing dhcpd.conf with computeresources objects.
* Create a straightforward installation process based on a single YAML file.
* Build support of alternative resource types (e.g., cloud systems, physical nodes and RPIs).
* Support of multiple master nodes, i.e., currently one is supported. 
* Improve documentation and create a website.

**Good luck!**
