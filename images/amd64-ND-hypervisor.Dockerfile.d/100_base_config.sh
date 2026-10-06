#!/bin/sh -eu

#- files in $0.d will be pupolualated to rootfs in /target
FSDIR="$0.d"
if [ -d "$FSDIR" ]; then
  . "/src/img-mangler.Dockerfile.d/100_add_files.sh"
else
  . "$SRC/lib.sh"; init
fi


# Configure timezone - global standard
chroot /target ln -sf /usr/share/zoneinfo/UTC /etc/localtime


# Add/Block default kernel drivers
chroot /target /bin/bash -c '\
  echo "blacklist amdgpu" > /etc/modprobe.d/blacklist-amdgpu.conf" \
  echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf" \
  echo "blacklist snd_hda_intel" > /etc/modprobe.d/blacklist-snd-intel.conf" \
  echo "nvme_rdma" > /etc/modprobe.d/nvme.conf" \
  echo "nbd" > /etc/modprobe.d/nbd.conf" \
  '


# Configure default logrotate rules
chroot /target /etc/logrotate.d/rsyslog <<'EOF'
# Default config from ND-hypervisor image

/var/log/syslog
/var/log/mail.info
/var/log/mail.warn
/var/log/mail.err
/var/log/mail.log
/var/log/daemon.log
/var/log/kern.log
/var/log/auth.log
/var/log/user.log
/var/log/lpr.log
/var/log/cron.log
/var/log/debug
/var/log/messages
{
        rotate 4
        weekly
        size 1G
        missingok
        notifempty
        compress
        delaycompress
        sharedscripts
        postrotate
                /usr/lib/rsyslog/rsyslog-rotate
        endscript
}
EOF
chroot /target chmod 444 /etc/logrotate.d/rsyslog


# Configure default iproute2 rules
chroot /target /etc/iproute2/rt_protos.d/nd-netagent.conf <<'EOF'
# Default config from ND-hypervisor image

# Reserved protocols
23 ndnetagent
EOF
chroot /target chmod 444 /etc/iproute2/rt_protos.d/nd-netagent.conf


# Install and configure irqbalance
# Hardware interrupt distribution over cores with Arch awareness
chroot /target apt clean
chroot /target apt update

chroot /target apt -y irqbalance
chroot /target systemctl enable irqbalance


# Ship sysctl settings
chroot /target /etc/sysctl.d/10-disable-rp-filter.conf <<'EOF'
# Default config from ND-hypervisor image

# Disable reverse-path filtering
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
EOF
chroot /target chmod 444 /etc/sysctl.d/10-disable-rp-filter.conf

chroot /target /etc/sysctl.d/10-enable-forwarding.conf <<'EOF'
# Default config from ND-hypervisor image

# Enable IPv4 forwarding
net.ipv4.ip_forward=1

# Allow source addresses present locally as source address
net.ipv4.conf.all.accept_local=1

# Enable IPv6 forwarding
net.ipv6.conf.all.forwarding=1
EOF
chroot /target chmod 444 /etc/sysctl.d/10-enable-forwarding.conf

chroot /target /etc/sysctl.d/10-icmp-errors-use-inbount-interface-address.conf <<'EOF'
# Default config from ND-hypervisor image

# Send ICMP errors from primary address of ingress interface
net.ipv4.icmp_errors_use_inbound_ifaddr=1
EOF
chroot /target chmod 444 /etc/sysctl.d/10-icmp-errors-use-inbount-interface-address.conf

