
<p align="center">
    <img src="clusterslice-logo.svg" alt="Welcome to ClusterSlice" width="400">
</p>

# Welcome to ClusterSlice!

ClusterSlice is an open-source solution for large-scale, kubernetes-centered experimentation. It supports a declarative specification of experimentation slices, their deployment over multiple test-beds and domains, the utilization of heterogeneous physical and virtual resources, as well as multiple kubernetes flavors, network plugins, and plug-and-play application features.

It introduces well-designed abstractions that reduce experimentation complexity with improved reliability and reproducibility. 

# Teaser Video
[![asciicast](https://asciinema.org/a/uqWSBv3JBv0X3wdvfzgSoIe26.svg)](https://asciinema.org/a/uqWSBv3JBv0X3wdvfzgSoIe26)

# Features

* [Declarative Experimentation Slices](/docs/README.md#declarative-definition-of-experimentation-slices): Experimenters can define experimentation slices in the form of YAML files. These slices specify the cloud resources to be utilized, the Kubernetes configuration, and the application modules to be installed. All of these aspects are defined in a declarative manner.
* [Configurable Physical and Virtual Resources](/docs/README.md#infrastructure-configuration): ClusterSlice supports the utilization of heterogeneous physical and virtual resources, including those utilized from open test-bed infrastructures (e.g., CloudLab), as well as VMs allocated in XCP-NG and VirtualBox virtualization systems.
* [Kubernetes Flavors and Network Plugins](/docs/README.md#kubernetes-configuration): We support multiple Kubernetes flavors, such as vanilla Kubernetes, k0s, k3s, and microk8s, as well as network plugins for both intra-cluster (e.g., flannel, calico, cilium, kuberouter, kube-ovn, etc.) and inter-cluster communication (e.g., submariner).
* [Kubernetes Extensions and Applications](/docs/README.md#application-modules-configuration): An experimentation slice supports the definition of applications to deploy, k8s extensions as well as modular OS configurations, all in the form of configurable application modules. 
* [Multi-Clustering and Multi-Domain Capabilities](/docs/README.md#multi-clustering-and-multi-domain-capabilities): ClusterSlice can operate across multiple heterogeneous deployment environments through technology-specific infrastructure managers, establishing specific multi-clustering capabilities such as Liqo, OCM, or Submariner.
* [Experimentation Automation](/docs/README.md#experimentation-automation): Experimentation automation capabilities are not only supported but also actively developed, making the deployment and management of experiments straightforward.

# Additional Resources

- [ClusterSlice Manual](/docs/README.md)
- [ClusterSlice Installation and Administration Guide](/install/README.md)

# Reference
Please cite this paper, if you use ClusterSlice:
- L. Mamatas, S.Skaperas, and Ilias Sakellariou, "[ClusterSlice: Slicing Resources for Zero-touch Kubernetes-based Experimentation](/docs/clusterslice-2023.pdf)", Technical Report, University of Macedonia, November 2023.

# Support

Contact [Lefteris Mamatas](https://sites.google.com/site/emamatas/) from University of Macedonia, Greece.

# License

ClusterSlice is released under the [Eclipse Public License 2.0](./LICENSE).

# Acknowledgement

This software was partially supported by the Greek Ministry of Education and Religious Affairs for the project "Enhancing Research and optimizing University of Macedonia’s administrative operation".
