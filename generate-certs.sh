#!/bin/sh

CONTROLLER_NAME=`hostname`
CONTROLLER_IP=$(getent ahostsv4 $CONTROLLER_NAME|tail -1|awk '{print $1}')
SERVICE_IP="10.254.0.1"

mkdir -p etc/kubernetes/pki
cd etc/kubernetes/pki

echo "Generate openssl.cnf"
cat > openssl.cnf << EOF
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

echo "Generate Kubernetes CA cert"
openssl ecparam -name secp521r1 -genkey -noout -out ca.key
chmod 0600 ca.key
openssl req -x509 -new -sha256 -nodes -key ca.key -days 3650 -out ca.crt \
        -subj "/CN=kubernetes-ca"  -extensions v3_ca -config ./openssl.cnf

echo "Generate kube apiserver cert"
openssl ecparam -name secp521r1 -genkey -noout -out kube-apiserver.key
chmod 0600 kube-apiserver.key
openssl req -new -sha256 -key kube-apiserver.key -subj "/CN=kube-apiserver" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out kube-apiserver.crt -days 365 \
                 -extensions v3_req_apiserver -extfile ./openssl.cnf

echo "Generate apiserver kubelet client cert"
openssl ecparam -name secp521r1 -genkey -noout -out apiserver-kubelet-client.key
chmod 0600 apiserver-kubelet-client.key
openssl req -new -key apiserver-kubelet-client.key \
            -subj "/CN=kube-apiserver-kubelet-client/O=system:masters" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out apiserver-kubelet-client.crt -days 365 \
                 -extensions v3_req_client -extfile ./openssl.cnf

echo "Generate admin client cert"
openssl ecparam -name secp521r1 -genkey -noout -out admin.key
chmod 0600 admin.key
openssl req -new -key admin.key -subj "/CN=kubernetes-admin/O=system:masters" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out admin.crt -days 365 -extensions v3_req_client \
                 -extfile ./openssl.cnf

echo "Generate Service Account key"
openssl ecparam -name secp521r1 -genkey -noout -out sa.key
openssl ec -in sa.key -outform PEM -pubout -out sa.pub
chmod 0600 sa.key
openssl req -new -sha256 -key sa.key \
            -subj "/CN=system:kube-controller-manager" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out sa.crt -days 365 -extensions v3_req_client \
                 -extfile ./openssl.cnf

echo "Generate kube-scheduler cert"
openssl ecparam -name secp521r1 -genkey -noout -out kube-scheduler.key
chmod 0600 kube-scheduler.key
openssl req -new -sha256 -key kube-scheduler.key \
            -subj "/CN=system:kube-scheduler" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out kube-scheduler.crt -days 365 -extensions v3_req_client \
                 -extfile ./openssl.cnf

echo "Generate front proxy CA cert"
openssl ecparam -name secp521r1 -genkey -noout -out front-proxy-ca.key
chmod 0600 front-proxy-ca.key
openssl req -x509 -new -sha256 -nodes -key front-proxy-ca.key -days 3650 \
            -out front-proxy-ca.crt -subj "/CN=front-proxy-ca" \
            -extensions v3_ca -config ./openssl.cnf

echo "Generate front proxy client cert"
openssl ecparam -name secp521r1 -genkey -noout -out front-proxy-client.key
chmod 0600 front-proxy-client.key
openssl req -new -sha256 -key front-proxy-client.key \
            -subj "/CN=front-proxy-client" \
  | openssl x509 -req -sha256 -CA front-proxy-ca.crt \
                 -CAkey front-proxy-ca.key -CAcreateserial \
                 -out front-proxy-client.crt -days 365 \
                 -extensions v3_req_client -extfile ./openssl.cnf

echo "Generate kube-proxy cert"
openssl ecparam -name secp521r1 -genkey -noout -out kube-proxy.key
chmod 0600 kube-proxy.key
openssl req -new -key kube-proxy.key \
            -subj "/CN=kube-proxy/O=system:node-proxier" \
  | openssl x509 -req -sha256 -CA ca.crt -CAkey ca.key -CAcreateserial \
                 -out kube-proxy.crt -days 365 -extensions v3_req_client \
                 -extfile ./openssl.cnf

echo "Generate etcd CA cert"
openssl ecparam -name secp521r1 -genkey -noout -out etcd-ca.key
chmod 0600 etcd-ca.key
openssl req -x509 -new -sha256 -nodes -key etcd-ca.key -days 3650 \
            -out etcd-ca.crt -subj "/CN=etcd-ca" -extensions v3_ca \
            -config ./openssl.cnf

echo "Generate etcd cert"
openssl ecparam -name secp521r1 -genkey -noout -out etcd.key
chmod 0600 etcd.key
openssl req -new -sha256 -key etcd.key -subj "/CN=etcd" \
  | openssl x509 -req -sha256 -CA etcd-ca.crt -CAkey etcd-ca.key \
                 -CAcreateserial -out etcd.crt -days 365 \
                 -extensions v3_req_etcd -extfile ./openssl.cnf

echo "Generate etcd peer cert"
openssl ecparam -name secp521r1 -genkey -noout -out etcd-peer.key
chmod 0600 etcd-peer.key
openssl req -new -sha256 -key etcd-peer.key -subj "/CN=etcd-peer" \
  | openssl x509 -req -sha256 -CA etcd-ca.crt -CAkey etcd-ca.key \
                 -CAcreateserial -out etcd-peer.crt -days 365 \
                 -extensions v3_req_etcd -extfile ./openssl.cnf

echo "View certs"
for i in *crt; do
    echo $i:;
    openssl x509 -subject -issuer -noout -in $i;
    echo;
  done
