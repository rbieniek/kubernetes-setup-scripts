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
- etc/kubernetes/bootstrap.kubeconfig

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
- etc/kubernetes/kubelet

## Prepare deployment
Remove old content from */etc/etcd* and */etc/kubernetes* directories
```
$ sudo rm -rf /etc/etcd /etc/kubernetes
```

and execute
```
$ sudo cp -r etc /
```

to deploy the created configuration files

## Fix permissions
Execute
```
$ sudo sh fix-permissions.sh
```

to give proper ownership to */etc/etcd* and */etc/kubernetes* directories

## Deploy etcd
Start *etcd* and make it start up during boot time by executing
```
$ sudo systemctl start etcd
$ sudo systemctl enable etcd
```

### Verify etc is working
Check *etcd* operation by excuting
``` 
$ sudo etcdctl --ca-file=/etc/etcd/pki/ca.crt --cert-file=/etc/etcd/pki/etcd.crt --key-file=/etc/etcd/pki/etcd.key cluster-health
$ sudo etcdctl --ca-file=/etc/etcd/pki/ca.crt --cert-file=/etc/etcd/pki/etcd.crt --key-file=/etc/etcd/pki/etcd.key  member list
```
The outpout of these commands should look like this
```
$ sudo etcdctl --ca-file=/etc/etcd/pki/ca.crt --cert-file=/etc/etcd/pki/etcd.crt --key-file=/etc/etcd/pki/etcd.key cluster-health
member 8e9e05c52164694d is healthy: got healthy result from http://192.168.65.128:2379
cluster is healthy
sudo etcdctl --ca-file=/etc/etcd/pki/ca.crt --cert-file=/etc/etcd/pki/etcd.crt --key-file=/etc/etcd/pki/etcd.key  member list
8e9e05c52164694d: name=default peerURLs=http://localhost:2380 clientURLs=http://192.168.65.128:2379 isLeader=true
```

## Deploy control plane
Start *kube-apiserver*, *kube-controller-manager* and *kube-scheduler* and
make them start during boot time by executing
```
$ sudo systemctl start kube-apiserver
$ sudo systemctl enable kube-apiserver
$ sudo systemctl start kube-controller-manager
$ sudo systemctl enable kube-controller-manager
$ sudo systemctl start kube-scheduler
$ sudo systemctl enable kube-scheduler
```

### Verify control plane deployment
The verify backplane deployment, issue
```
$ sudo bash -login
# export KUBECONFIG=/etc/kubernetes/admin.kubeconfig
# kubectl version
# kubectl get componentstatuses
```

which should output similar to this:
```
$ sudo bash -login
# export KUBECONFIG=/etc/kubernetes/admin.kubeconfig
# kubectl version
Client Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.1", GitCommit:"d4ab47518836c750f9949b9e0d387f20fb92260b", GitTreeState:"archive", BuildDate:"2018-04-26T09:29:05Z", GoVersion:"go1.10.1", Compiler:"gc", Platform:"linux/amd64"}
Server Version: version.Info{Major:"1", Minor:"10", GitVersion:"v1.10.1", GitCommit:"d4ab47518836c750f9949b9e0d387f20fb92260b", GitTreeState:"archive", BuildDate:"2018-04-26T09:29:05Z", GoVersion:"go1.10.1", Compiler:"gc", Platform:"linux/amd64"}
# kubectl get componentstatuses
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok                   
controller-manager   Healthy   ok                   
etcd-0               Healthy   {"health": "true"}   
```
