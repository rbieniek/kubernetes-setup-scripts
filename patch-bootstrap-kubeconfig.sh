#!/bin/sh

CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
INTERNAL_IP=$(hostname -I | awk '{print $1}')
KUBERNETES_PUBLIC_ADDRESS=$INTERNAL_IP

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

CLUSTER_NAME="default"
BOOTSTRAP_KCONFIG=${KUBE_DIR}/bootstrap.kubeconfig
BOOTSTRAP_TOKEN_FILE=${KUBE_DIR}/bootstrap.token
BOOTSTRAP_KUSER="kubelet-bootstrap"
BOOTSTRAP_KCERT=sa

mkdir -p ${KUBE_DIR}

if [ ! -f ${BOOTSTRAP_TOKEN_FILE} ]; then
    echo "Create bootstrap token file ${BOOTSTRAP_TOKEN_FILE} first"
    exit 1
fi

BOOTSTRAP_TOKEN=`cat ${BOOTSTRAP_TOKEN}`

if [ ! -f ${BOOTSTRAP_KCONFIG} ]; then
    echo "Generate $BOOTSTRAP_KCONFIG first"
    exit 1
else
    echo "Patching bootstrap token ${BOOTSTRAP_KCONFIG} into config $BOOTSTRAP_KCONFIG"    

    kubectl config set-credentials ${BOOTSTRAP_KUSER} \
	    --token=${BOOTSTRAP_TOKEN} \
	    --kubeconfig=${BOOTSTRAP_KCONFIG}
fi
