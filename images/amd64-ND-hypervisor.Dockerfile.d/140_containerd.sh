#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"

set -x


#apt install -y \
#  containerd \
#  cni-plugins \
#  crictl \
#  nerdctl \
#  runc
case "$(uname -m)" in
  x86_64|amd64)   ARCH=amd64 ;;
  aarch64|arm64)  ARCH=arm64 ;;
  ppc64le)        ARCH=ppc64le ;;
  s390x)          ARCH=s390x ;;
  riscv64)        ARCH=riscv64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac


# inject taiga-pkgs-repo key
cat > /etc/apt/keyrings/taiga-pkgs-repo.asc <<'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----

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
=dAd6
-----END PGP PUBLIC KEY BLOCK-----
EOF
chmod 444 /etc/apt/keyrings/taiga-pkgs-repo.asc

# add taiga mirrors
cat > /etc/apt/sources.list.d/taiga-pkgs.list <<'EOF'
# Default config from ND-hypervisor image

Types: deb
URIs: http://taiga-pkgs.lefdal.northerndata.tech/debian
Suites: trixie
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/taiga-pkgs-repo.asc
EOF
chmod 444 /etc/apt/sources.list.d/taiga-pkgs.list
###
## ABOVE IS USED TO use APT to install packages. Although they are outdated
### Adding here for testing purposes, need to check available versions


# Install containerd from the bakery
# #cd "$(mktemp -d)"
CONTAINERD_REPO=https://github.com/containerd/containerd.git
LATEST=$(git ls-remote --tags --refs --sort=-v:refname "$CONTAINERD_REPO" 'v[0-9]*' \
  | awk '{sub("refs/tags/","",$2); print $2}' \
  | grep -Ev -- '-(alpha|beta|rc)' \
  | head -n1)

wget -6 https://github.com/containerd/containerd/releases/download/${LATEST}/containerd-${LATEST#v}-linux-${ARCH}.tar.gz --output-document containerd.tar.gz
tar -C /usr/local -xzf containerd.tar.gz

curl -fL -o /etc/systemd/system/containerd.service \
  "https://raw.githubusercontent.com/containerd/containerd/${LATEST}/containerd.service"
systemctl enable containerd.service

mkdir -p /etc/containerd/conf.d
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null


# Install cni from the butcher
CNI_REPO=https://github.com/containernetworking/plugins.git
LATEST=$(git ls-remote --tags --refs --sort=-v:refname "$CNI_REPO" 'v[0-9]*' \
  | awk '{sub("refs/tags/","",$2); print $2}' \
  | grep -Ev -- '-(alpha|beta|rc)' \
  | head -n1)

wget -6 https://github.com/containernetworking/plugins/releases/download/${LATEST}/cni-plugins-linux-${ARCH}-${LATEST}.tgz \
  --output-document containernetworking.tgz
mkdir -p /opt/cni/bin
tar -C /opt/cni/bin -xzf containernetworking.tgz
# keep previous permissions for this file, just in case someone injects keys
chmod 440 /etc/containerd/config.toml
# guarantee that service is marked as enabled
systemctl enable containerd.service


# RUNC meddles with apparmor and other things, so lets use the apt bin for
# now...
apt install -y runc
## Install runc from the farm
# See https://github.com/opencontainers/runc/releases
#RUNC_REPO=https://github.com/opencontainers/runc.git
#LATEST=$(git ls-remote --tags --refs --sort=-v:refname "$RUNC_REPO" 'v[0-9]*' \
#  | awk '{sub("refs/tags/","",$2); print $2}' \
#  | grep -Ev -- '-(alpha|beta|rc)' \
#  | head -n1)
#
#wget -6 https://github.com/opencontainers/runc/releases/download/${ARCH}/runc.${ARCH} \
#  --output-document runc.deb
#dpkg -i runc.deb


# Install nerdctl from college
NERDCTL_REPO=https://github.com/containerd/nerdctl.git
LATEST=$(git ls-remote --tags --refs --sort=-v:refname "$NERDCTL_REPO" 'v[0-9]*' \
  | awk '{sub("refs/tags/","",$2); print $2}' \
  | grep -Ev -- '-(alpha|beta|rc)' \
  | head -n1)

wget -6 https://github.com/containerd/nerdctl/releases/download/${LATEST}/nerdctl-${LATEST#v}-linux-${ARCH}.tar.gz \
  --output-document nerdctl.tar.gz
tar -C /usr/local/bin -xzf nerdctl.tar.gz


# Install crictl from the alpine glaciers
NERDCTL_REPO=https://github.com/kubernetes-sigs/cri-tools.git
LATEST=$(git ls-remote --tags --refs --sort=-v:refname "$NERDCTL_REPO" 'v[0-9]*' \
  | awk '{sub("refs/tags/","",$2); print $2}' \
  | grep -Ev -- '-(alpha|beta|rc)' \
  | head -n1)
wget -6 https://github.com/kubernetes-sigs/cri-tools/releases/download/${LATEST}/crictl-${LATEST}-linux-${ARCH}.tar.gz \
  --output-document crictl.tar.gz
tar zxvf crictl.tar.gz -C /usr/local/bin


# apply crictl default configs
cat > /etc/crictl.yaml <<'EOF'
# Default config from ND-hypervisor image

runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF
chmod 644 /etc/crictl.yaml


#rm -f crictl-$VERSION-linux-amd64.tar.gz


##### SECRETS AND CONFIGS CAN BE INJECTED FROM THE CI-DATA DISK
##### INTO THE /etc/containerd/conf.d/ PATH !!!!!!
###########
## EXAMPLE
##
### /etc/containerd/conf.d/10-registry-bar.toml
##[plugins."io.containerd.cri.v1.images".registry.configs."bar.example.com".auth]
##  username = "bar"
##  password = "{{ user_registry.bar }}"
##
## chmod 440 -R /etc/containerd/conf.d/*
###########

# Configure containerd runner
#cat > /etc/containerd/config.toml <<'EOF'
## Default config from ND-hypervisor image
#
#disabled_plugins = []
#imports = []
#oom_score = 0
#plugin_dir = ""
#required_plugins = []
#root = "/var/lib/containerd"
#state = "/run/containerd"
#temp = ""
#version = 2
#
#[cgroup]
#  path = ""
#
#[debug]
#  address = ""
#  format = ""
#  gid = 0
#  level = ""
#  uid = 0
#
#[grpc]
#  address = "/run/containerd/containerd.sock"
#  gid = 0
#  max_recv_message_size = 16777216
#  max_send_message_size = 16777216
#  tcp_address = ""
#  tcp_tls_ca = ""
#  tcp_tls_cert = ""
#  tcp_tls_key = ""
#  uid = 0
#
#[metrics]
#  address = ""
#  grpc_histogram = false
#
#[plugins]
#
#  [plugins."io.containerd.gc.v1.scheduler"]
#    deletion_threshold = 0
#    mutation_threshold = 100
#    pause_threshold = 0.02
#    schedule_delay = "0s"
#    startup_delay = "100ms"
#
#  [plugins."io.containerd.grpc.v1.cri"]
#    device_ownership_from_security_context = false
#    disable_apparmor = false
#    disable_cgroup = false
#    disable_hugetlb_controller = true
#    disable_proc_mount = false
#    disable_tcp_service = true
#    enable_selinux = false
#    enable_tls_streaming = false
#    enable_unprivileged_icmp = false
#    enable_unprivileged_ports = false
#    ignore_image_defined_volumes = false
#    max_concurrent_downloads = 3
#    max_container_log_line_size = 16384
#    netns_mounts_under_state_dir = false
#    restrict_oom_score_adj = false
#    sandbox_image = "k8s.gcr.io/pause:3.6"
#    selinux_category_range = 1024
#    stats_collect_period = 10
#    stream_idle_timeout = "4h0m0s"
#    stream_server_address = "127.0.0.1"
#    stream_server_port = "0"
#    systemd_cgroup = false
#    tolerate_missing_hugetlb_controller = true
#    unset_seccomp_profile = ""
#
#    [plugins."io.containerd.grpc.v1.cri".cni]
#      bin_dir = "/opt/cni/bin"
#      conf_dir = "/etc/cni/net.d"
#      conf_template = ""
#      ip_pref = ""
#      max_conf_num = 1
#
#    [plugins."io.containerd.grpc.v1.cri".containerd]
#      default_runtime_name = "runc"
#      disable_snapshot_annotations = true
#      discard_unpacked_layers = false
#      ignore_rdt_not_enabled_errors = false
#      no_pivot = false
#      snapshotter = "overlayfs"
#
#      [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime]
#        base_runtime_spec = ""
#        cni_conf_dir = ""
#        cni_max_conf_num = 0
#        container_annotations = []
#        pod_annotations = []
#        privileged_without_host_devices = false
#        runtime_engine = ""
#        runtime_path = ""
#        runtime_root = ""
#        runtime_type = ""
#
#        [plugins."io.containerd.grpc.v1.cri".containerd.default_runtime.options]
#
#      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
#
#        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#          base_runtime_spec = ""
#          cni_conf_dir = ""
#          cni_max_conf_num = 0
#          container_annotations = []
#          pod_annotations = []
#          privileged_without_host_devices = false
#          runtime_engine = ""
#          runtime_path = ""
#          runtime_root = ""
#          runtime_type = "io.containerd.runc.v2"
#
#          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#            BinaryName = ""
#            CriuImagePath = ""
#            CriuPath = ""
#            CriuWorkPath = ""
#            IoGid = 0
#            IoUid = 0
#            NoNewKeyring = false
#            NoPivotRoot = false
#            Root = ""
#            ShimCgroup = ""
#            SystemdCgroup = true
#
#      [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime]
#        base_runtime_spec = ""
#        cni_conf_dir = ""
#        cni_max_conf_num = 0
#        container_annotations = []
#        pod_annotations = []
#        privileged_without_host_devices = false
#        runtime_engine = ""
#        runtime_path = ""
#        runtime_root = ""
#        runtime_type = ""
#
#        [plugins."io.containerd.grpc.v1.cri".containerd.untrusted_workload_runtime.options]
#
#    [plugins."io.containerd.grpc.v1.cri".image_decryption]
#      key_model = "node"
#
#    [plugins."io.containerd.grpc.v1.cri".registry]
#      config_path = ""
#
#      [plugins."io.containerd.grpc.v1.cri".registry.auths]
#
#      [plugins."io.containerd.grpc.v1.cri".registry.configs]
#
#      [plugins."io.containerd.grpc.v1.cri".registry.headers]
#
#      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
#
#    [plugins."io.containerd.grpc.v1.cri".x509_key_pair_streaming]
#      tls_cert_file = ""
#      tls_key_file = ""
#
#  [plugins."io.containerd.internal.v1.opt"]
#    path = "/opt/containerd"
#
#  [plugins."io.containerd.internal.v1.restart"]
#    interval = "10s"
#
#  [plugins."io.containerd.internal.v1.tracing"]
#    sampling_ratio = 1.0
#    service_name = "containerd"
#
#  [plugins."io.containerd.metadata.v1.bolt"]
#    content_sharing_policy = "shared"
#
#  [plugins."io.containerd.monitor.v1.cgroups"]
#    no_prometheus = false
#
#  [plugins."io.containerd.runtime.v1.linux"]
#    no_shim = false
#    runtime = "runc"
#    runtime_root = ""
#    shim = "containerd-shim"
#    shim_debug = false
#
#  [plugins."io.containerd.runtime.v2.task"]
#    platforms = ["linux/amd64"]
#    sched_core = false
#
#  [plugins."io.containerd.service.v1.diff-service"]
#    default = ["walking"]
#
#  [plugins."io.containerd.service.v1.tasks-service"]
#    rdt_config_file = ""
#
#  [plugins."io.containerd.snapshotter.v1.aufs"]
#    root_path = ""
#
#  [plugins."io.containerd.snapshotter.v1.btrfs"]
#    root_path = ""
#
#  [plugins."io.containerd.snapshotter.v1.devmapper"]
#    async_remove = false
#    base_image_size = ""
#    discard_blocks = false
#    fs_options = ""
#    fs_type = ""
#    pool_name = ""
#    root_path = ""
#
#  [plugins."io.containerd.snapshotter.v1.native"]
#    root_path = ""
#
#  [plugins."io.containerd.snapshotter.v1.overlayfs"]
#    root_path = ""
#    upperdir_label = false
#
#  [plugins."io.containerd.snapshotter.v1.zfs"]
#    root_path = ""
#
#  [plugins."io.containerd.tracing.processor.v1.otlp"]
#    endpoint = ""
#    insecure = false
#    protocol = ""
#
#[proxy_plugins]
#
#[stream_processors]
#
#  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar"]
#    accepts = ["application/vnd.oci.image.layer.v1.tar+encrypted"]
#    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
#    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
#    path = "ctd-decoder"
#    returns = "application/vnd.oci.image.layer.v1.tar"
#
#  [stream_processors."io.containerd.ocicrypt.decoder.v1.tar.gzip"]
#    accepts = ["application/vnd.oci.image.layer.v1.tar+gzip+encrypted"]
#    args = ["--decryption-keys-path", "/etc/containerd/ocicrypt/keys"]
#    env = ["OCICRYPT_KEYPROVIDER_CONFIG=/etc/containerd/ocicrypt/ocicrypt_keyprovider.conf"]
#    path = "ctd-decoder"
#    returns = "application/vnd.oci.image.layer.v1.tar+gzip"
#
#[timeouts]
#  "io.containerd.timeout.bolt.open" = "0s"
#  "io.containerd.timeout.shim.cleanup" = "5s"
#  "io.containerd.timeout.shim.load" = "5s"
#  "io.containerd.timeout.shim.shutdown" = "3s"
#  "io.containerd.timeout.task.state" = "2s"
#
#[ttrpc]
#  address = ""
#  gid = 0
#  uid = 0
#EOF
#chmod 440 /etc/containerd/config.toml
#systemctl enable containerd.service
