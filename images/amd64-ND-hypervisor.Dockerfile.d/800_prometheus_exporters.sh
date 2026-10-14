#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars

cd "$DST"


# create user for node_exporter
NODE_EXPORTER_UID="205"
useradd \
  --system \
  --uid 205 \
  --home-dir /opt/node-exporter \
  --create-home \
  --shell /usr/sbin/nologin \
  node-exporter


#mkdir -p /var/ndcloud/node-exporter/textfile-collector
#chown 205:205 /var/ndcloud/node-exporter/textfile-collector
#chmod 0755 /var/ndcloud/node-exporter/textfile-collector




#SO three things:
#* The kubelet manifest for the exporter
#* The nginx site pointing to the local port and the link with the page-name on nginx

