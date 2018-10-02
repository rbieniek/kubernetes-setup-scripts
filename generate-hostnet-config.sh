#!/bin/sh
CLUSTER_CIDR="10.254.0.0/16"

CNI_DIR=etc/cni/net.d

mkdir -p ${CNI_DIR}

if [ ! -f ${CNI_DIR}/10-hostnet.conf ]; then
    echo "Generate ${CNI_DIR}/10-hostnet.conf"
    cat <<EOF >${CNI_DIR}/10-hostnet.conf
{
	"cniVersion": "0.2.0",
	"name": "mynet",
	"type": "bridge",
	"bridge": "cni0",
	"isGateway": true,
	"ipMasq": true,
	"ipam": {
		"type": "host-local",
		"subnet": "${CLUSTER_CIDR}",
		"routes": [
			{ "dst": "0.0.0.0/0" }
		]
	}
}
EOF
else
    echo "Skipping ${CNI_DIR}/10-hostnet.conf"
fi

if [ ! -f ${CNI_DIR}/99-loopback.conf ]; then
    echo "Generate ${CNI_DIR}/99-loopback.conf"
    cat <<EOF >${CNI_DIR}/99-loopback.conf
{
	"cniVersion": "0.2.0",
	"name": "lo",
	"type": "loopback"
}
EOF
else
    echo "Skipping ${CNI_DIR}/99-loopback.conf"
fi
