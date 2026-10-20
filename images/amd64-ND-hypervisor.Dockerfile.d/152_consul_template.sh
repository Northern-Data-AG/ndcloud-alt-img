#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# versions
CONSUL_TEMPLATE_VERSION="0.29.0"

cd "$DST"


case "$(uname -m)" in
  x86_64|amd64)   ARCH=amd64 ;;
  aarch64|arm64)  ARCH=arm64 ;;
  ppc64le)        ARCH=ppc64le ;;
  s390x)          ARCH=s390x ;;
  riscv64)        ARCH=riscv64 ;;
  *) echo "unsupported arch: $(uname -m)" >&2; exit 1 ;;
esac

mkdir -p /etc/consul-template
mkdir -p /opt/consul-template
chmod 755 /etc/consul-template
chmod 755 /opt/consul-template

apt install -y unzip

wget -6 https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_${ARCH}.zip \
  --output-document consul_template.zip


# install consul template
set -e
#_TMP="$(mktemp -d)"
#trap 'rm -rf "$_TMP"' EXIT QUIT INT TERM PIPE HUP
#cd "$_TMP"
unzip consul_template.zip
CONSUL_BIN_PATH="/opt/consul-template/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_${ARCH}"
mv consul-template ${CONSUL_BIN_PATH}
chmod 555 ${CONSUL_BIN_PATH}
chown root:root ${CONSUL_BIN_PATH}
set +e


# apply default configs
cat > /etc/consul-template/config.hcl <<'EOF'
# Default config from ND-hypervisor image

vault {
    address = "https://bao.tyr.taigacloud.tech"

    vault_agent_token_file = "/run/consul_template.token"
    unwrap_token = false
    renew_token = false
}

syslog {
    enabled = false
}
EOF
chmod 440 /etc/consul-template/config.hcl

cat > /etc/systemd/system/consul-template.service <<EOF
# Default config from ND-hypervisor image

[Unit]
Description=Consul Template
Documentation=https://github.com/hashicorp/consul-template
After=network-online.target
StartLimitBurst=5
StartLimitIntervalSec=60

[Service]
Type=simple
SuccessExitStatus=12
ExecReload=/bin/kill -SIGHUP \$MAINPID
ExecStop=/bin/kill -SIGINT \$MAINPID
ExecStart=${CONSUL_BIN_PATH} \
    -config /etc/consul-template
Restart=on-failure
KillMode=process
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
chmod 444 /etc/systemd/system/consul-template.service

# NOT SURE THIS SURVIVES IMAGE
cat > /etc/tmpfiles.d/consul_template.conf <<'EOF'
# Default config from ND-hypervisor image

X /run/consul_template.token
EOF
chmod 444 /etc/tmpfiles.d/consul_template.conf


systemctl enable consul-template.service
