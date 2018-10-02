#!/bin/sh

DOCKER_DIR=etc/docker

mkdir -p ${DOCKER_DIR}

cat << EOF > ${DOCKER_DIR}/daemon.json 
{
	"exec-opts": ["native.cgroupdriver=cgroupfs"] 
}
EOF
