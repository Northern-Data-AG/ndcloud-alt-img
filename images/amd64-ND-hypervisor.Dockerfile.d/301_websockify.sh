#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars
CONTAINER_REGISTRY="harbor.tyr.taigacloud.tech"
WEBSOCKIFY_REPO_PATH="${CONTAINER_REGISTRY}/taiga"
WEBSOCKIFY_CONTAINER_TAG="0.11.0.20231108.083803"
# NOTE: THIS IS MEH, need to configure to pull from our repo
# REPO mirror should allow to use cached mirrors, available for all
# node in the cluster

cd "$DST"


# ship liveness checking script
cat > /src/websockify_liveness.py <<'EOF'
#!/usr/bin/env python3
# Default config from ND-hypervisor image

import libvirt
import sys
import logging

logs_format = '[%(asctime)s] %(levelname)s - %(message)s'
logger = logging.getLogger(__name__)
# make logs available in K8s logs – '/proc/1/fd/1' file is Pod STDOUT
handler = logging.FileHandler('/proc/1/fd/1', mode='w')
logger.setLevel({{liveness_probe_loglevel}})
formatter = logging.Formatter(logs_format)
handler.setFormatter(formatter)
logger.addHandler(handler)

try:
    conn = libvirt.open('qemu:///system')
    conn.close()
    logger.debug('QEMU / libvirtd running fine ...')
    sys.exit(0)
except libvirt.libvirtError as e:
    logger.error('QEMU / libvirtd socket not writable – container malfunctioning ...')
    sys.exit(1)
EOF
chmod 444 /src/websockify_liveness.py


# ship container manifest
cat > /opt/kubelet/manifests/websockify.yml <<EOF
# Default config from ND-hypervisor image

apiVersion: v1
kind: Pod
metadata:
  name: websockify
  labels:
    role: websockify
spec:
  hostNetwork: true
  volumes:
    - name: libvirt-socket
      hostPath:
        path: /var/run/libvirt/libvirt-sock
    - name: liveness-probe
      hostPath:
        path: /srv/websockify_liveness.py
  containers:
    - name: websockify
      image: ${WEBSOCKIFY_REPO_PATH}/websockify:${WEBSOCKIFY_CONTAINER_TAG}
      args: ["--token-plugin", "taiga_websockify.NDCloudToken.NDCloudToken", "[::1]:11000"]
      volumeMounts:
        - mountPath: /var/run/libvirt/libvirt-sock
          name: libvirt-socket
        - mountPath: /srv/websockify_liveness.py
          name: liveness-probe
      livenessProbe:
        exec:
          command:
            - python
            - /srv/websockify_liveness.py
          initialDelaySeconds: 5
          periodSeconds: 30
EOF
chmod 444 /opt/kubelet/manifests/websockify.yml


# ship and enable nginx location config
cat > /etc/nginx/locations-available/spice <<'EOF'
# Default config from ND-hypervisor image

location /spice/ {
    proxy_pass http://[::1]:11000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Host $http_host;
}
EOF
chmod 444 /etc/nginx/locations-available/spice
ln -sfn /etc/nginx/locations-available/spice /etc/nginx/locations-enabled/spice
