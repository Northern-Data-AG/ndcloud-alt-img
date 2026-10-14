#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


mkdir -p /etc/iptables
chmod 755 /etc/iptables


# ship ip6table rules
cat > /etc/iptables/rules.v6 <<'EOF'
# Default config from ND-hypervisor image

# this has alot of 'possibly' moving values
# so it needs to come from cloud-init client
# generator script with access to nautobot
EOF
chmod 444 /etc/iptables/rules.v6


# ship iptable rules
cat > /etc/iptables/rules.v4 <<'EOF'
# Default config from ND-hypervisor image

# this has alot of 'possibly' moving values
# so it needs to come from cloud-init client
# generator script with access to nautobot
EOF
chmod 444 /etc/iptables/rules.v4
