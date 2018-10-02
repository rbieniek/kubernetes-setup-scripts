#!/bin/sh
KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

BOOTSTRAP_KUBECONFIG_FILE=${KUBE_DIR}/bootstrap.kubeconfig
ADMIN_KUBECONFIG_FILE=${KUBE_DIR}/admin.kubeconfig

if [ ! -f ${BOOTSTRAP_KUBECONFIG_FILE} ]; then
    echo "Deploy ${BOOTSTRAP_KUBECONFIG_FILE} first"
    exit 1
fi

export KUBECONFIG=${ADMIN_KUBECONFIG_FILE}

kubectl -n kube-public create configmap cluster-info \
        --from-file ${KUBE_PKI_DIR}/ca.crt \
        --from-file ${BOOTSTRAP_KUBECONFIG_FILE}

kubectl -n kube-public create role system:bootstrap-signer-clusterinfo \
        --verb get --resource configmaps
kubectl -n kube-public create rolebinding kubeadm:bootstrap-signer-clusterinfo \
        --role system:bootstrap-signer-clusterinfo --user system:anonymous

kubectl create clusterrolebinding kubeadm:kubelet-bootstrap \
        --clusterrole system:node-bootstrapper --group system:bootstrappers
