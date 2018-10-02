#!/bin/sh

CONTROLLER_NAME=`hostname -s`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
INTERNAL_IP=$(hostname -I | awk '{print $1}')
KUBERNETES_PUBLIC_ADDRESS=$INTERNAL_IP
SERVICE_CLUSTER_IP_RANGE="10.254.0.0/12"
CLUSTER_CIDR="10.254.0.0/16"
SERVICE_CLUSTER_PORT_RANGE=30000-32767

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki
ETCD_DIR=etc/etcd
ETCD_PKI_DIR=${ETCD_DIR}/pki

ETCD_CERT_FILE=/${KUBE_PKI_DIR}/etcd.crt
ETCD_CERT_KEY_FILE=/${KUBE_PKI_DIR}/etcd.key
ETCD_CA_FILE=/${KUBE_PKI_DIR}/etcd-ca.crt

SA_ACCOUNT_KEY_FILE=/${KUBE_PKI_DIR}/sa.key
SA_ACCOUNT_PUB_FILE=/${KUBE_PKI_DIR}/sa.pub
KUBE_API_SERVER_SECURE_PORT=6443

KUBE_CA_CERT_FILE=/${KUBE_PKI_DIR}/ca.crt
KUBE_CA_KEY_FILE=/${KUBE_PKI_DIR}/ca.key
KUBE_APISERVER_CERT_FILE=/${KUBE_PKI_DIR}/kube-apiserver.crt
KUBE_APISERVER_KEY_FILE=/${KUBE_PKI_DIR}/kube-apiserver.key
KUBELET_CLIENT_CERT_FILE=/${KUBE_PKI_DIR}/apiserver-kubelet-client.crt
KUBELET_CLIENT_KEY_FILE=/${KUBE_PKI_DIR}/apiserver-kubelet-client.key
FRONT_PROXY_CERT_FILE=/${KUBE_PKI_DIR}/front-proxy-ca.crt
FRONT_PROXY_KEY_FILE=/${KUBE_PKI_DIR}/front-proxy-ca.key

if [ ! -f ${KUBE_DIR}/apiserver ]; then
    echo "Generate ${KUBE_DIR}/apiserver"

    cat >${KUBE_DIR}/apiserver <<EOF
#
# kubernetes system config
#
# The following values are used to configure the kube-apiserver
#

# The address on the local server to listen to.
KUBE_API_ADDRESS="--bind-address=0.0.0.0 --advertise-address=${INTERNAL_IP} --insecure-bind-address=127.0.0.1"

# The port on the local server to listen on.
# KUBE_API_PORT="--port=8080"
KUBE_API_PORT="--secure-port=${KUBE_API_SERVER_SECURE_PORT} --insecure-port=0"

# Port minions listen on
# KUBELET_PORT="--kubelet-port=10250"

# Comma separated list of nodes in the etcd cluster
KUBE_ETCD_SERVERS="--etcd-servers=https://${INTERNAL_IP}:2379 --etcd-cafile=${ETCD_CA_FILE} --etcd-certfile=${ETCD_CERT_FILE} --etcd-keyfile=${ETCD_CERT_KEY_FILE}"

# Address range to use for services
KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} --service-node-port-range=${SERVICE_CLUSTER_PORT_RANGE}"

# default admission control policies
KUBE_ADMISSION_CONTROL="--admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds,NodeRestriction  --service-account-key-file=${SA_ACCOUNT_KEY_FILE} --authorization-mode=Node,RBAC"

# Add your own!
KUBE_API_ARGS="--client-ca-file=${KUBE_CA_CERT_FILE} --tls-cert-file=${KUBE_APISERVER_CERT_FILE} --tls-private-key-file=${KUBE_APISERVER_KEY_FILE} --enable-bootstrap-token-auth=true --kubelet-client-certificate=${KUBELET_CLIENT_CERT_FILE} --kubelet-client-key=${KUBELET_CLIENT_KEY_FILE} --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname --requestheader-client-ca-file=${FRONT_PROXY_CERT_FILE} --requestheader-username-headers=X-Remote-User --requestheader-group-headers=X-Remote-Group --requestheader-allowed-names=front-proxy-client --requestheader-extra-headers-prefix=X-Remote-Extra-"

EOF

else
    echo "Skip  ${KUBE_DIR}/apiserver"
fi

if [ ! -f ${KUBE_DIR}/config ]; then
    echo "Generate ${KUBE_DIR}/config"

    cat >${KUBE_DIR}/config <<EOF
###
# kubernetes system config
#
# The following values are used to configure various aspects of all
# kubernetes services, including
#
#   kube-apiserver.service
#   kube-controller-manager.service
#   kube-scheduler.service
#   kubelet.service
#   kube-proxy.service
# logging to stderr means we get it in the systemd journal
KUBE_LOGTOSTDERR="--logtostderr=true"

# journal message level, 0 is debug
KUBE_LOG_LEVEL="--v=2"

# Should this cluster be allowed to run privileged docker containers
KUBE_ALLOW_PRIV="--allow-privileged=true"

# How the controller-manager, scheduler, and proxy find the apiserver
# KUBE_MASTER="--master=https://${KUBERNETES_PUBLIC_ADDRESS}:${KUBE_API_SERVER_SECURE_PORT}"
# Not used here, server is configured in *.kubeconfig files
KUBE_MASTER=

EOF
else
    echo "Skip  ${KUBE_DIR}/config"
fi

if [ ! -f ${KUBE_DIR}/controller-manager ]; then
    echo "Generate ${KUBE_DIR}/controller-manager"

    cat >${KUBE_DIR}/controller-manager <<EOF
###
# The following values are used to configure the kubernetes controller-manager

# defaults from config and apiserver should be adequate

# Add your own!
KUBE_CONTROLLER_MANAGER_ARGS="--kubeconfig=/${KUBE_DIR}/controller-manager.kubeconfig --address=127.0.0.1 --leader-elect=true --controllers=*,bootstrapsigner,tokencleaner --service-account-private-key-file=${SA_ACCOUNT_KEY_FILE} --insecure-experimental-approve-all-kubelet-csrs-for-group=system:bootstrappers --cluster-cidr=${CLUSTER_CIDR} --cluster-name=${CLUSTER_NAME} --service-cluster-ip-range=${SERVICE_CLUSTER_IP_RANGE} --cluster-signing-cert-file=${KUBE_CA_CERT_FILE} --cluster-signing-key-file=${KUBE_CA_KEY_FILE} --root-ca-file=${KUBE_CA_CERT_FILE} --use-service-account-credentials=true"

EOF
else
    echo "Skip  ${KUBE_DIR}/controller-manager"
fi

if [ ! -f ${KUBE_DIR}/scheduler ]; then
    echo "Generate ${KUBE_DIR}/scheduler"

    cat >${KUBE_DIR}/scheduler <<EOF
###
# kubernetes scheduler config

# default config should be adequate

# Add your own!
KUBE_SCHEDULER_ARGS="--leader-elect=true --kubeconfig=/${KUBE_DIR}/scheduler.kubeconfig --address=127.0.0.1"

EOF
else
    echo "Skip  ${KUBE_DIR}/scheduler"
fi
