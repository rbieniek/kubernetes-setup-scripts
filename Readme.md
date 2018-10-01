# Kubernetes-Setup-Scripts
This collection of scripts support setting up a running Kubernetes cluster on Fedora 28 following
the guidelines shown in the Kubernetes documentation [https://kubernetes.io/docs/getting-started-guides/fedora/fedora_manual_config/ "Fedora (Single Node)"] and this blog post
[https://nixaid.com/deploying-kubernetes-cluster-from-scratch/ "Deploying Kubernetes cluster from scratch"]

This guide assumes a running docker installation according to this documentation
[https://docs.docker.com/install/linux/docker-ce/fedora/ "Get Docker CE for Fedora"]

The scripts currently setup the Kubernetes master and node processes on the same box. This is just for
setting up a local development environment, there is no technical reason which prevents the scripts from being used to create a multi-node setup.


## Preparations
Install Kubernetes as shown but make sure, the Kubernetes system service are not running.

```
$ sudo systemctl stop etcd.service \
  kube-controller-manager.service \
  kube-scheduler.service \
  kube-apiserver.service \
  kubelet.service \
  kube-proxy.service
```

## Generate sysct.d configuration
It is necessary to have bridge netfilter and IP forwarding configuration applied.

The *etc/sysctl.d/kubernetes.conf* configuration file is generated using
```
sh generate-sysctl-conf.sh 
```

The generated configuration file enables IP forwading as well as IPv4 and IPV6 bridge
netfiltr support.

## Generate certificates
The script generates a custom CA used for encrypting and protecting cluster communications.

The certificates and all other relevant files are created like this:

```
sh ./generate-certs.sh

```

As a output of this script, the directories *etc/etcd/pki* and *etc/kubernetes/pki*
are created and populated

## Generate etcd configuration
To create the etcd configuration, use this script:

```
sh ./generate-etcd-config.sh

```

This creates a etcd configuration set up for encrypted communication

## Generate kubeconfig files
To create the necessary kubeconfig files (with embedded certificates), use this script:

```
sh generate-kubeconfig.sh 
```

This creates the Kubernetes config files:
- etc/kubernetes/admin.kubeconfig
- etc/kubernetes/controller-manager.kubeconfig
- etc/kubernetes/scheduler.kubeconfig

## Generate the controller backplane configuration files
To generate the configuration files for *kube-apiserver*, *kube-controller-manager* and
*kube-scheduler*, use this script:

```
sh generate-control-plane.sh
```

This creates the Kubernetes service config files:
- etc/kubernetes/apiserver
- etc/kubernetes/config
- etc/kubernetes/controller-manager
- etc/kubernetes/scheduler

