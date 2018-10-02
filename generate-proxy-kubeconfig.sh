#!/bin/sh
CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
INTERNAL_IP=$(hostname -I | awk '{print $1}')
KUBERNETES_PUBLIC_ADDRESS=$INTERNAL_IP
CLUSTER_NAME="default"

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

ADMIN_KUBECONFIG_FILE=${KUBE_DIR}/admin.kubeconfig
PROXY_KUBECONFIG_FILE=${KUBE_DIR}/kube-proxy.kubeconfig

mkdir -p ${KUBE_DIR}

if [ ! -f ${PROXY_KUBECONFIG_FILE} ]; then
    echo "Generate ${PROXY_KUBECONFIG_FILE}"
    
    export KUBECONFIG=${KUBE_DIR}/admin.kubeconfig

    kubectl -n kube-system create serviceaccount kube-proxy

    SECRET=$(kubectl -n kube-system get sa/kube-proxy --output=jsonpath='{.secrets[0].name}')
    JWT_TOKEN=$(kubectl -n kube-system get secret/$SECRET --output=jsonpath='{.data.token}' | base64 -d)

    kubectl config set-cluster ${CLUSTER_NAME} \
	    --certificate-authority=${KUBE_PKI_DIR}/ca.crt \
	    --embed-certs=true \
	    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
	    --kubeconfig=${PROXY_KUBECONFIG_FILE}

    kubectl config set-context ${CLUSTER_NAME} \
	    --cluster=${CLUSTER_NAME} \
	    --user=default \
	    --namespace=default \
	    --kubeconfig=${PROXY_KUBECONFIG_FILE}

    kubectl config set-credentials ${CLUSTER_NAME} \
	    --token=${JWT_TOKEN} \
	    --kubeconfig=${PROXY_KUBECONFIG_FILE}

    kubectl config use-context ${CLUSTER_NAME} --kubeconfig=${PROXY_KUBECONFIG_FILE}
    kubectl config view --kubeconfig=${PROXY_KUBECONFIG_FILE}

    kubectl create clusterrolebinding kubeadm:node-proxier --clusterrole system:node-proxier --serviceaccount kube-system:kube-proxy
else
    echo "Skipping generate ${PROXY_KUBECONFIG_FILE}"
fi

