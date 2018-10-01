#!/bin/sh

CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
SERVICE_IP="10.254.0.1"

KUBE_PKI_DIR=etc/kubernetes/pki
ETCD_PKI_DIR=etc/etcd/pki


mkdir -p ${KUBE_PKI_DIR}
mkdir -p ${ETCD_PKI_DIR}


if [ ! -f ${KUBE_PKI_DIR}/openssl.cnf ]; then
    echo "Generate openssl.cnf"
    cat > ${KUBE_PKI_DIR}/openssl.cnf << EOF
[ req ]
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_ca ]
basicConstraints = critical, CA:TRUE
keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign
[ v3_req_server ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
[ v3_req_client ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
[ v3_req_apiserver ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names_cluster
[ v3_req_etcd ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names_etcd
[ alt_names_cluster ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster.local
DNS.5 = ${CONTROLLER_NAME}
IP.1 = ${CONTROLLER_IP}
IP.2 = ${SERVICE_IP}
[ alt_names_etcd ]
DNS.1 = ${CONTROLLER_NAME}
IP.1 = ${CONTROLLER_IP}
EOF

    cp  ${KUBE_PKI_DIR}/openssl.cnf  ${ETCD_PKI_DIR}
else
    echo "Skip openssl.cnf"
fi

if [ ! -f ${KUBE_PKI_DIR}/ca.key ]; then
    echo "Generate Kubernetes CA cert"
    openssl ecparam -name secp521r1 -genkey -noout -out ${KUBE_PKI_DIR}/ca.key
    chmod 0600  ${KUBE_PKI_DIR}/ca.key
    openssl req -x509 -new -sha256 -nodes -key  ${KUBE_PKI_DIR}/ca.key -days 3650 -out  ${KUBE_PKI_DIR}/ca.crt \
            -subj "/CN=kubernetes-ca"  -extensions v3_ca -config  ${KUBE_PKI_DIR}//openssl.cnf
else
    echo "Skip Kubernetes CA cet"
fi


if [ ! -f ${KUBE_PKI_DIR}/kube-apiserver.key ]; then
    echo "Generate kube apiserver cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/kube-apiserver.key
    chmod 0600  ${KUBE_PKI_DIR}/kube-apiserver.key
    openssl req -new -sha256 -key  ${KUBE_PKI_DIR}/kube-apiserver.key -subj "/CN=kube-apiserver" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/kube-apiserver.crt -days 365 \
                 -extensions v3_req_apiserver -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip kube apisperver cert"
fi

if [ ! -f ${KUBE_PKI_DIR}/apiserver-kubelet-client.key ]; then
    echo "Generate apiserver kubelet client cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/apiserver-kubelet-client.key
    chmod 0600  ${KUBE_PKI_DIR}/apiserver-kubelet-client.key
    openssl req -new -key  ${KUBE_PKI_DIR}/apiserver-kubelet-client.key \
            -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/apiserver-kubelet-client.crt -days 365 \
                 -extensions v3_req_client -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip apiserver kubelet client cert"
fi

if [ ! -f ${KUBE_PKI_DIR}/admin.key ]; then
    echo "Generate admin client cert"
    openssl ecparam -name secp521r1 -genkey -noout -out ${KUBE_PKI_DIR}/admin.key
    chmod 0600  ${KUBE_PKI_DIR}/admin.key
    openssl req -new -key  ${KUBE_PKI_DIR}/admin.key -subj "/CN=kubernetes-admin/O=system:masters" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/admin.crt -days 365 -extensions v3_req_client \
                 -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip admin client cert"
fi

if [ ! -f ${KUBE_PKI_DIR}/sa.key ]; then
    echo "Generate Service Account key"
    openssl ecparam -name secp521r1 -genkey -noout -out ${KUBE_PKI_DIR}/sa.key
    openssl ec -in  ${KUBE_PKI_DIR}/sa.key -outform PEM -pubout -out  ${KUBE_PKI_DIR}/sa.pub
    chmod 0600  ${KUBE_PKI_DIR}/sa.key
    openssl req -new -sha256 -key  ${KUBE_PKI_DIR}/sa.key \
            -subj "/CN=system:kube-controller-manager" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/sa.crt -days 365 -extensions v3_req_client \
                 -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip Service Account key"
fi

if [ ! -f ${KUBE_PKI_DIR}/kube-scheduler.key ]; then
    echo "Generate kube-scheduler cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/kube-scheduler.key
    chmod 0600  ${KUBE_PKI_DIR}/kube-scheduler.key
    openssl req -new -sha256 -key  ${KUBE_PKI_DIR}/kube-scheduler.key \
            -subj "/CN=system:kube-scheduler" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/kube-scheduler.crt -days 365 -extensions v3_req_client \
                 -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip kube-scheduler cert"
fi

if [ ! -f  ${KUBE_PKI_DIR}/front-proxy-ca.key ]; then
    echo "Generate front proxy CA cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/front-proxy-ca.key
    chmod 0600  ${KUBE_PKI_DIR}/front-proxy-ca.key
    openssl req -x509 -new -sha256 -nodes -key  ${KUBE_PKI_DIR}/front-proxy-ca.key -days 3650 \
            -out  ${KUBE_PKI_DIR}/front-proxy-ca.crt -subj "/CN=front-proxy-ca" \
            -extensions v3_ca -config  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip front proxy CA cert"
fi

if [ ! -f ${KUBE_PKI_DIR}/front-proxy-client.key ]; then
    echo "Generate front proxy client cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/front-proxy-client.key
    chmod 0600  ${KUBE_PKI_DIR}/front-proxy-client.key
    openssl req -new -sha256 -key  ${KUBE_PKI_DIR}/front-proxy-client.key \
            -subj "/CN=front-proxy-client" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/front-proxy-ca.crt \
                 -CAkey  ${KUBE_PKI_DIR}/front-proxy-ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/front-proxy-client.crt -days 365 \
                 -extensions v3_req_client -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip front proxy client cert"
fi

if [ ! -f ${KUBE_PKI_DIR}/kube-proxy.key ]; then
    echo "Generate kube-proxy cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${KUBE_PKI_DIR}/kube-proxy.key
    chmod 0600  ${KUBE_PKI_DIR}/kube-proxy.key
    openssl req -new -key  ${KUBE_PKI_DIR}/kube-proxy.key \
            -subj "/CN=kube-proxy/O=system:node-proxier" \
	| openssl x509 -req -sha256 -CA  ${KUBE_PKI_DIR}/ca.crt -CAkey  ${KUBE_PKI_DIR}/ca.key -CAcreateserial \
                 -out  ${KUBE_PKI_DIR}/kube-proxy.crt -days 365 -extensions v3_req_client \
                 -extfile  ${KUBE_PKI_DIR}/openssl.cnf
else
    echo "Skip kube-proxy cert"
fi

if [ ! -f ${ETCD_PKI_DIR}/ca.key ]; then
    echo "Generate etcd CA cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${ETCD_PKI_DIR}/ca.key
    chmod 0600  ${ETCD_PKI_DIR}/ca.key
    openssl req -x509 -new -sha256 -nodes -key  ${ETCD_PKI_DIR}/ca.key -days 3650 \
            -out  ${ETCD_PKI_DIR}/ca.crt -subj "/CN=ca" -extensions v3_ca \
            -config  ${ETCD_PKI_DIR}/openssl.cnf
    cp ${ETCD_PKI_DIR}/ca.crt ${KUBE_PKI_DIR}/etcd-ca.crt
else
    echo "Skip etcd CA cert"
fi

if [ ! -f ${ETCD_PKI_DIR}/etcd.key ]; then
    echo "Generate etcd cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${ETCD_PKI_DIR}/etcd.key
    chmod 0600  ${ETCD_PKI_DIR}/etcd.key
    openssl req -new -sha256 -key  ${ETCD_PKI_DIR}/etcd.key -subj "/CN=etcd" \
	| openssl x509 -req -sha256 -CA  ${ETCD_PKI_DIR}/ca.crt -CAkey  ${ETCD_PKI_DIR}/ca.key \
                 -CAcreateserial -out  ${ETCD_PKI_DIR}/etcd.crt -days 365 \
                 -extensions v3_req_etcd -extfile  ${ETCD_PKI_DIR}/openssl.cnf

    cp ${ETCD_PKI_DIR}/etcd.key ${ETCD_PKI_DIR}/etcd.crt ${KUBE_PKI_DIR}
else
    echo "Skip etcd cert"
fi


if [ ! -f ${ETCD_PKI_DIR}/etcd-peer.key ]; then
    echo "Generate etcd peer cert"
    openssl ecparam -name secp521r1 -genkey -noout -out  ${ETCD_PKI_DIR}/etcd-peer.key
    chmod 0600  ${ETCD_PKI_DIR}/etcd-peer.key
    openssl req -new -sha256 -key  ${ETCD_PKI_DIR}/etcd-peer.key -subj "/CN=etcd-peer" \
	| openssl x509 -req -sha256 -CA  ${ETCD_PKI_DIR}/ca.crt -CAkey  ${ETCD_PKI_DIR}/ca.key \
                 -CAcreateserial -out  ${ETCD_PKI_DIR}/etcd-peer.crt -days 365 \
                 -extensions v3_req_etcd -extfile  ${ETCD_PKI_DIR}/openssl.cnf
else
    echo "Skip etcd peer cert"
fi

(
    echo "View Kubernetes certs"
    cd ${KUBE_PKI_DIR}
    for i in *crt; do
	echo $i:;
	openssl x509 -subject -issuer -noout -in $i;
	echo;
    done
)

(
    echo "View etcd certs"
    cd ${ETCD_PKI_DIR}
    for i in *crt; do
	echo $i:;
	openssl x509 -subject -issuer -noout -in $i;
	echo;
    done
)
