#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


# Setup nvme multipath
apt install -y multipath-tools
cat > /etc/multipath.conf <<'EOF'
# Default config from ND-hypervisor image

defaults {
    path_selector            "queue-length 0"
    path_grouping_policy     multibus
    fast_io_fail_tmo         10
    user_friendly_names      no
    no_path_retry            queue
    features                 0
    dev_loss_tmo             60
    polling_interval         10
    uid_attribute            ID_WWN
    find_multipaths          no
    path_checker             rdma
    max_fds                  65535
}

blacklist {
    device {
        product ".*"
    }
}

blacklist_exceptions {
    device {
        product "(PURE|Pure).*"
    }
}
EOF
chmod 444 /etc/multipath.conf


# Configure IP Quality of Service [QoS]
cat > /opt/qos.sh <<'EOF'
#!/bin/bash
# Default config from ND-hypervisor image

shopt -s nullglob

for f in /sys/class/infiniband/*;
do
    iface=$(basename "$f")
    echo "setting TOS for IB interface: $iface"
    mkdir -p "/sys/kernel/config/rdma_cm/$iface/ports/1"
    echo 106 > "/sys/kernel/config/rdma_cm/$iface/ports/1/default_roce_tos"
done

for i in uplink0 uplink1;
do
    if ip link show $i;
    then
        echo "setting dscp trust for interface:" $i
        mlnx_qos -i $i --trust=dscp --pfc=0,0,0,1,0,0,0,0
    fi
done
EOF
chmod 555 /opt/qos.sh

cat > /etc/systemd/system/nvme_qos.service <<'EOF'
# Default config from ND-hypervisor image

[Unit]
Description=QOS persistent configuration
Requires=network.target
After=modules-load.service network.target

[Service]
Type=oneshot
ExecStart=/opt/qos.sh
StandardOutput=journal

[Install]
WantedBy=default.target
EOF
chmod 444 /etc/systemd/system/nvme_qos.service
systemctl enable nvme_qos.service


# Install required packages for HOST nvme control
apt install -y nvme-cli
# Warning: Remove nvme unique identifiers from seed
rm /etc/nvme/hostnqn
rm /etc/nvme/hostid
cat > /etc/systemd/system/nvme-hostid-init.service <<'EOF'
# Default config from ND-hypervisor image

[Unit]
Description=Generate unique NVMe host NQN/ID on first boot
ConditionFirstBoot=yes
Before=nvmf-autoconnect.service network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/bin/mkdir -p /etc/nvme
ExecStart=/bin/sh -c 'nvme gen-hostnqn > /etc/nvme/hostnqn'
ExecStart=/bin/sh -c 'sed "s/.*uuid://" /etc/nvme/hostnqn > /etc/nvme/hostid'

[Install]
WantedBy=multi-user.target
EOF
chmod 644 /etc/systemd/system/nvme-hostid-init.service


# Add nvme connect scripts and respective service
cat > /etc/systemd/system/nvme_connect.service <<'EOF'
# Default config from ND-hypervisor image

[Unit]
Description=NVMeoF persistent connection
Requires=networking.service nvme_qos.service
After=systemd-modules-load.service network.target nvme_qos.service frr.service
StartLimitBurst=5
StartLimitIntervalSec=60

[Service]
Type=oneshot
ExecStart=/opt/nvme_connect.sh
StandardOutput=journal
TimeoutSec=180s
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target timers.target
EOF
chmod 444 /etc/systemd/system/nvme_connect.service
systemctl enable nvme_connect.service
