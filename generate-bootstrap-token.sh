#!/bin/sh

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

BOOTSTRAP_TOKEN_FILE=${KUBE_DIR}/bootstrap.token

mkdir -p ${KUBE_DIR}

if [ ! -f ${BOOTSTRAP_TOKEN_FILE} ]; then
    echo "Generate ${BOOTSTRAP_TOKEN_FILE}"
    
    TOKEN_PUB=$(openssl rand -hex 3)
    TOKEN_SECRET=$(openssl rand -hex 8)
    BOOTSTRAP_TOKEN="${TOKEN_PUB}.${TOKEN_SECRET}"

    echo -n >${BOOTSTRAP_TOKEN_FILE} ${BOOTSTRAP_TOKEN}

    export KUBECONFIG=${KUBE_DIR}/admin.kubeconfig
    
    kubectl -n kube-system create secret generic bootstrap-token-${TOKEN_PUB} \
        --type 'bootstrap.kubernetes.io/token' \
        --from-literal description="cluster bootstrap token" \
        --from-literal token-id=${TOKEN_PUB} \
        --from-literal token-secret=${TOKEN_SECRET} \
        --from-literal usage-bootstrap-authentication=true \
        --from-literal usage-bootstrap-signing=true

    kubectl -n kube-system get secret/bootstrap-token-${TOKEN_PUB} -o yaml

    chmod 600 ${BOOTSTRAP_TOKEN_FILE}
else
    echo "Skipping generate ${BOOTSTRAP_TOKEN_FILE}"    
fi

