#!/bin/sh

SYSCTL_DIR=etc/sysctl.d

mkdir -p ${SYSCTL_DIR}

cat <<EOF >${SYSCTL_DIR}/kubernetes.conf
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
EOF
