#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


apt install -y ntpsec
mkdir -p /etc/ntpsec
cat > /etc/ntpsec/ntp.conf << 'EOF' 
# Default config from ND-hypervisor image

driftfile /var/lib/ntpsec/ntp.drift

leapfile /usr/share/zoneinfo/leap-seconds.list

statistics loopstats peerstats clockstats

filegen loopstats file loopstats type day enable
filegen peerstats file peerstats type day enable
filegen clockstats file clockstats type day enable

# ??? This needs to come from cloud-init
## list of ntp servers
#{% for item in supportserver_primary_ip6 %}
#server {{ item }} iburst
#{% endfor %}

# By default, heavily restrict access
restrict default kod nomodify notrap nopeer noquery limited

# Local users may interrogate the ntp server more closely.
restrict 127.0.0.1
restrict ::1
EOF
chmod 444 /etc/ntpsec/ntp.conf
