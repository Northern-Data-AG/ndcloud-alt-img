#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


apt install -y lldpd

cat > /etc/lldpd.d/interfaces.conf <<'EOF'
# Default config from ND-hypervisor image

configure system interface pattern eth*,enp*,eno*,lo,uplink*
EOF
chmod 444 /etc/lldpd.d/interfaces.conf
