#!/bin/sh

ADDON_MANAGER_VERSION=v8.8

KUBE_DIR=etc/kubernetes
KUBE_PKI_DIR=${KUBE_DIR}/pki

( cat <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: kube-addon-manager
  namespace: kube-system
  labels:
    component: kube-addon-manager
spec:
  hostNetwork: true
  containers:
  - name: kube-addon-manager
    image: gcr.io/google-containers/kube-addon-manager:${ADDON_MANAGER_VERSION}
    command:
    - /bin/bash
    - -c
    - /opt/kube-addons.sh 1>>/var/log/kube-addon-manager.log 2>&1
    resources:
      requests:
        cpu: 5m
        memory: 50Mi
    volumeMounts:
    - mountPath: /etc/kubernetes/
      name: addons
      readOnly: true
    - mountPath: /var/log
      name: varlog
      readOnly: false
  volumes:
  - hostPath:
      path: /etc/kubernetes/
    name: addons
  - hostPath:
      path: /var/log
    name: varlog
EOF
) | kubectl --kubeconfig=${KUBE_DIR}/admin.kubeconfig apply -f -

