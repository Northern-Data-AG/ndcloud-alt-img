#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# versions
NGINX_CONTAINER_TAG="1.27.1"
# NOTE: THIS IS MEH, need to configure to pull from our repo
# REPO mirror should allow to use cached mirrors, available for all
# node in the cluster

cd "$DST"


# create nginx folder tree
mkdir -p /etc/nginx/conf.d
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available
mkdir -p /etc/nginx/stream-sites-enabled
mkdir -p /etc/nginx/stream-sites-available
mkdir -p /etc/nginx/locations-enabled
mkdir -p /etc/nginx/locations-available
chmod 755 -R /etc/nginx

# add protected certs file
mkdir -p /etc/nginx/certs
chmod 550 /etc/nginx/certs


# deploy nginx config
cat > /etc/nginx/nginx.conf <<'EOF'
# Default config from ND-hypervisor image

user www-data;
worker_processes 4;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
}

http {
    client_max_body_size 100m;
    sendfile on;
    tcp_nopush off;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_names_hash_bucket_size 128;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    ssl_protocols TLSv1.3;
    ssl_prefer_server_ciphers off;

    ssl_session_timeout 1d;
    ssl_session_cache shared:MozSSL:10m;
    ssl_session_tickets off;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;
}

stream {
    include /etc/nginx/stream-sites-enabled/*;
}
EOF
chmod 444 /etc/nginx/nginx.conf


# add/enable nginx service
cat > /etc/nginx/sites-available/default <<'EOF'
# Default config from ND-hypervisor image

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    # We want to fail, if someone is not using https. We don't want to redirect automatically.
    root /var/www/html;
    index index.html;

    server_name _;

    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;

    location / {
        autoindex off;
    }
}
EOF
chmod 444 /etc/nginx/sites-available/default
# and enable default website
ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default
chown -h root:root /etc/nginx/sites-enabled/default


# make sure nginx root folder exists
mkdir -p /var/www/html
chmod 755 /var/www/html
chown -h root:root /var/www/html


# add default index.html
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
    <head>
    </head>
    <body>
        &nbsp;
    </body>
</html>
EOF
chmod 444 /var/www/html/index.html
chown www-data:www-data /var/www/html/index.html


# pre-pull container
# containerd socket does not exist.
# also sec should pull image ALWAYS
#ctr -n k8s.io images pull \
#        docker.io/library/nginx:${NGINX_CONTAINER_TAG}


# disable host nginx.service
systemctl disable nginx.service 2>/dev/null || true


# add nginx manifest to node containers
mkdir -p /opt/kubelet/manifests
cat > /opt/kubelet/manifests/nginx.yml <<'EOF'
# Default config from ND-hypervisor image

apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    role: nginx
spec:
  hostNetwork: true
  volumes:
    - name: nginx-config
      hostPath:
        path: /etc/nginx/nginx.conf
    - name: nginx-confd
      hostPath:
        path: /etc/nginx/conf.d
    - name: nginx-sites-enabled
      hostPath:
        path: /etc/nginx/sites-enabled
    - name: nginx-sites-available
      hostPath:
        path: /etc/nginx/sites-available
    - name: nginx-stream-sites-enabled
      hostPath:
        path: /etc/nginx/stream-sites-enabled
    - name: nginx-stream-sites-available
      hostPath:
        path: /etc/nginx/stream-sites-available
    - name: nginx-locations-enabled
      hostPath:
        path: /etc/nginx/locations-enabled
    - name: nginx-locations-available
      hostPath:
        path: /etc/nginx/locations-available
    - name: nginx-certs
      hostPath:
        path: /etc/nginx/certs
    - name: nginx-data
      hostPath:
        path: /var/www/html
  containers:
    - name: nginx
      image: docker.io/library/nginx:${NGINX_CONTAINER_TAG}
      volumeMounts:
        - mountPath: /etc/nginx/nginx.conf
          name: nginx-config
        - mountPath: /etc/nginx/conf.d
          name: nginx-confd
        - mountPath: /etc/nginx/sites-enabled
          name: nginx-sites-enabled
        - mountPath: /etc/nginx/sites-available
          name: nginx-sites-available
        - mountPath: /etc/nginx/stream-sites-enabled
          name: nginx-stream-sites-enabled
        - mountPath: /etc/nginx/stream-sites-available
          name: nginx-stream-sites-available
        - mountPath: /etc/nginx/locations-enabled
          name: nginx-locations-enabled
        - mountPath: /etc/nginx/locations-available
          name: nginx-locations-available
        - mountPath: /etc/nginx/certs
          name: nginx-certs
        - mountPath: /var/www/html
          name: nginx-data
EOF
chmod 444 /opt/kubelet/manifests/nginx.yml
