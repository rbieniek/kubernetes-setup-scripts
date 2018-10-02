#!/bin/sh
CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
INTERNAL_IP=$(hostname -I | awk '{print $1}')
KUBERNETES_PUBLIC_ADDRESS=$INTERNAL_IP
CLUSTER_NAME="default"

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

ADMIN_KUBECONFIG_FILE=${KUBE_DIR}/admin.kubeconfig

export KUBECONFIG=${ADMIN_KUBECONFIG_FILE}

export KUBE_VERSION=$(kubectl version | base64 | tr -d '\n')

kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=${KUBE_VERSION}"

