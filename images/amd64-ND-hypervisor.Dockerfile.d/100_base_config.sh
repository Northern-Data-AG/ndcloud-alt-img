#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


# Configure timezone - global standard
ln -sf /usr/share/zoneinfo/UTC /etc/localtime


# Add/Block default kernel drivers
echo "blacklist amdgpu" > /etc/modprobe.d/blacklist-amdgpu.conf
echo "blacklist nouveau" > /etc/modprobe.d/blacklist-nouveau.conf
echo "blacklist snd_hda_intel" > /etc/modprobe.d/blacklist-snd-intel.conf
echo "nvme_rdma" > /etc/modules-load.d/nvme.conf
echo "nbd" > /etc/modules-load.d/nbd.conf


# Configure default logrotate rules
cat > /etc/logrotate.d/rsyslog <<'EOF'
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
chmod 444 /etc/logrotate.d/rsyslog


# Configure default iproute2 rules
cat > /etc/iproute2/rt_protos.d/nd-netagent.conf <<'EOF'
# Default config from ND-hypervisor image

# Reserved protocols
23 ndnetagent
EOF
chmod 444 /etc/iproute2/rt_protos.d/nd-netagent.conf


# Install and configure irqbalance
# Hardware interrupt distribution over cores with Arch awareness
apt clean
apt update

apt install -y irqbalance
systemctl enable irqbalance


# Ship sysctl settings
cat > /etc/sysctl.d/10-disable-rp-filter.conf <<'EOF'
# Default config from ND-hypervisor image

# Disable reverse-path filtering
net.ipv4.conf.default.rp_filter=0
net.ipv4.conf.all.rp_filter=0
EOF
chmod 444 /etc/sysctl.d/10-disable-rp-filter.conf

cat > /etc/sysctl.d/10-enable-forwarding.conf <<'EOF'
# Default config from ND-hypervisor image

# Enable IPv4 forwarding
net.ipv4.ip_forward=1

# Allow source addresses present locally as source address
net.ipv4.conf.all.accept_local=1

# Enable IPv6 forwarding
net.ipv6.conf.all.forwarding=1
EOF
chmod 444 /etc/sysctl.d/10-enable-forwarding.conf

cat > /etc/sysctl.d/10-icmp-errors-use-inbount-interface-address.conf <<'EOF'
# Default config from ND-hypervisor image

# Send ICMP errors from primary address of ingress interface
net.ipv4.icmp_errors_use_inbound_ifaddr=1
EOF
chmod 444 /etc/sysctl.d/10-icmp-errors-use-inbount-interface-address.conf


# Trigger trusted certificate DB rebuild
cat | tee /usr/local/share/ca-certificates/nd-ca.crt /etc/ssl/certs/nd-ca.crt << 'EOF'
-----BEGIN CERTIFICATE-----
MIIDSDCCAjCgAwIBAgIUCRDcOcsTScqc8i38qpCpf6WqsFowDQYJKoZIhvcNAQEL
BQAwHDEaMBgGA1UEAxMRbm9ydGhlcm5kYXRhLnRlY2gwHhcNMjIwNjIxMTAyMDQ0
WhcNMzIwNjE4MTAyMTEzWjAcMRowGAYDVQQDExFub3J0aGVybmRhdGEudGVjaDCC
ASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAJunXMEhZxInD4drMdg5Q9Rs
8Fx1g8Uyy2qeDzkuFH+TPmlT4WqKKlDpCxS13sND9xGov+BDEZm9QEYz22HLdBI4
5j217j2vUmXyHBBnl5+YYG+LgiolgBkm+4DOTGcP5Ikf5tllnovIsDOJreQilCEv
2/SLOd+diJboiZUn3GUDUeSyhgRfRI8UG8Met3TH6muXdqAIuHNmGFRZ9dClk9W+
gmtdk500oIvhgKpB9vTBaq3DAJMC5vocssethRUm3TKRY4WUXQhJxD771tNbTBH+
+Ih1sFGFiTglFOft6PMemy5PCyYOnR0FpnBY7fErebT6dEG/RVy46eGK10ez+r8C
AwEAAaOBgTB/MA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
DgQWBBS9sCAl6RpLClsjDj91tVtcYqKf7TAfBgNVHSMEGDAWgBS9sCAl6RpLClsj
Dj91tVtcYqKf7TAcBgNVHREEFTATghFub3J0aGVybmRhdGEudGVjaDANBgkqhkiG
9w0BAQsFAAOCAQEAjjdHfplAtwu58SfY4VY8dtZuYAmkPwqmPT8ZEWMX+xUE1d/y
PA0fThW8yEJ/772KNXWVtPSbsd9qUf7gMsWHLA6SdKPrfngCE5CPDIEG4omvCFlL
QG9mZM0mWDZiEgKjge4eiS6aEU0qfnXewpptXQGs2vGQHniwv0fBI12UpIoAVBOX
f75/mDWkeUKttvhiXOgi4bqgYt7f8C6Pi6Y32ttzkDFa8w+PXdXb3FlP0Rswc+id
C5Dt60TE8P0+X+TwksN2qttT/0P46RaS9iDAWquPQwHSpCGogx5AcDalQDUrDXfE
6vI/OaqUtCqbWWvI3lLqqHAfY4tRCfzXqyjaeA==
-----END CERTIFICATE-----
EOF
update-ca-certificates
