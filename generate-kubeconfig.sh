#!/bin/sh

CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
INTERNAL_IP=$(hostname -I | awk '{print $1}')
KUBERNETES_PUBLIC_ADDRESS=$INTERNAL_IP

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

CLUSTER_NAME="default"
CONTROLLER_MANAGER_KCONFIG=${KUBE_DIR}/controller-manager.kubeconfig
CONTROLLER_MANAGER_KUSER="system:kube-controller-manager"
CONTROLLER_MANAGER_KCERT=sa

mkdir -p ${KUBE_DIR}

if [ ! -f ${CONTROLLER_MANAGER_KCONFIG} ]; then
    echo "Generate $CONTROLLER_MANAGER_KCONFIG"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
	    --certificate-authority=${KUBE_PKI_DIR}/ca.crt \
	    --embed-certs=true \
	    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
	    --kubeconfig=${CONTROLLER_MANAGER_KCONFIG}

    kubectl config set-credentials ${CONTROLLER_MANAGER_KUSER} \
	    --client-certificate=${KUBE_PKI_DIR}/${CONTROLLER_MANAGER_KCERT}.crt \
	    --client-key=${KUBE_PKI_DIR}/${CONTROLLER_MANAGER_KCERT}.key \
	    --embed-certs=true \
	    --kubeconfig=${CONTROLLER_MANAGER_KCONFIG}

    kubectl config set-context ${CONTROLLER_MANAGER_KUSER}@${CLUSTER_NAME} \
	    --cluster=${CLUSTER_NAME} \
	    --user=${CONTROLLER_MANAGER_KUSER} \
	    --kubeconfig=${CONTROLLER_MANAGER_KCONFIG}

    kubectl config use-context ${CONTROLLER_MANAGER_KUSER}@${CLUSTER_NAME} --kubeconfig=${CONTROLLER_MANAGER_KCONFIG}
    kubectl config view --kubeconfig=${CONTROLLER_MANAGER_KCONFIG}
else
    echo "Skip $CONTROLLER_MANAGER_KCONFIG"    
fi

KUBE_SCHEDULER_KCONFIG=${KUBE_DIR}/scheduler.kubeconfig
KUBE_SCHEDULER_KUSER="system:kube-scheduler"
KUBE_SCHEDULER_KCERT=kube-scheduler

if [ ! -f ${KUBE_SCHEDULER_KCONFIG} ]; then
    echo "Generate ${KUBE_SCHEDULER_KCONFIG}"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
	    --certificate-authority=${KUBE_PKI_DIR}/ca.crt \
	    --embed-certs=true \
	    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
	    --kubeconfig=${KUBE_SCHEDULER_KCONFIG}

    kubectl config set-credentials ${KUBE_SCHEDULER_KUSER} \
	    --client-certificate=${KUBE_PKI_DIR}/${KUBE_SCHEDULER_KCERT}.crt \
	    --client-key=${KUBE_PKI_DIR}/${KUBE_SCHEDULER_KCERT}.key \
	    --embed-certs=true \
	    --kubeconfig=${KUBE_SCHEDULER_KCONFIG}

    kubectl config set-context ${KUBE_SCHEDULER_KUSER}@${CLUSTER_NAME} \
	    --cluster=${CLUSTER_NAME} \
	    --user=${KUBE_SCHEDULER_KUSER} \
	    --kubeconfig=${KUBE_SCHEDULER_KCONFIG}

    kubectl config use-context ${KUBE_SCHEDULER_KUSER}@${CLUSTER_NAME} --kubeconfig=${KUBE_SCHEDULER_KCONFIG}
    kubectl config view --kubeconfig=${KUBE_SCHEDULER_KCONFIG}
else
    echo "Skip ${KUBE_SCHEDULER_KCONFIG}"
fi

ADMIN_KCONFIG=${KUBE_DIR}/admin.kubeconfig
ADMIN_KUSER="kubernetes-admin"
ADMIN_KCERT=admin

if [ ! -f ${ADMIN_KCONFIG} ]; then
    echo "Generate ${ADMIN_KCONFIG}"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
	    --certificate-authority=${KUBE_PKI_DIR}/ca.crt \
	    --embed-certs=true \
	    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
	    --kubeconfig=${ADMIN_KCONFIG}

    kubectl config set-credentials ${ADMIN_KUSER} \
	    --client-certificate=${KUBE_PKI_DIR}/${ADMIN_KCERT}.crt \
	    --client-key=${KUBE_PKI_DIR}/${ADMIN_KCERT}.key \
	    --embed-certs=true \
	    --kubeconfig=${ADMIN_KCONFIG}

    kubectl config set-context ${ADMIN_KUSER}@${CLUSTER_NAME} \
	    --cluster=${CLUSTER_NAME} \
	    --user=${ADMIN_KUSER} \
	    --kubeconfig=${ADMIN_KCONFIG}

    kubectl config use-context ${ADMIN_KUSER}@${CLUSTER_NAME} --kubeconfig=${ADMIN_KCONFIG}
    kubectl config view --kubeconfig=${ADMIN_KCONFIG}

else
    echo "Skip ${ADMIN_KCONFIG}"
fi

BOOTSTRAP_KCONFIG=${KUBE_DIR}/bootstrap.kubeconfig
BOOTSTRAP_KUSER="kubelet-bootstrap"

mkdir -p ${KUBE_DIR}

if [ ! -f ${BOOTSTRAP_KCONFIG} ]; then
    echo "Generate $BOOTSTRAP_KCONFIG"
    
    kubectl config set-cluster ${CLUSTER_NAME} \
	    --certificate-authority=${KUBE_PKI_DIR}/ca.crt \
	    --embed-certs=true \
	    --server=https://${KUBERNETES_PUBLIC_ADDRESS}:6443 \
	    --kubeconfig=${BOOTSTRAP_KCONFIG}

    kubectl config set-context ${BOOTSTRAP_KUSER}@${CLUSTER_NAME} \
	    --cluster=${CLUSTER_NAME} \
	    --user=${BOOTSTRAP_KUSER} \
	    --kubeconfig=${BOOTSTRAP_KCONFIG}

    kubectl config use-context ${BOOTSTRAP_KUSER}@${CLUSTER_NAME} --kubeconfig=${BOOTSTRAP_KCONFIG}
    kubectl config view --kubeconfig=${BOOTSTRAP_KCONFIG}

    chmod 600 ${BOOTSTRAP_KCONFIG}
else
    echo "Skip $BOOTSTRAP_KCONFIG"    
fi
