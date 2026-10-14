#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars
VAULT_SERVER_FQDN="bao.tyr.taigacloud.tech"

CONTAINER_REGISTRY="container.lefdal.northerndata.tech"
VAULT_REPO_PATH="${CONTAINER_REGISTRY}"
VAULT_AGENT_VERSION="1.10.4"

cd "$DST"


mkdir -p /etc/vault-agent


# Add default configs
cat > /etc/vault-agent/config.hcl <<'EOF'
# Default config from ND-hypervisor image

auto_auth {
    method {
        type = "approle"

        config = {
            role_id_file_path = "/vault/config/consul_template.id"
            secret_id_file_path = "/vault/config/consul_template.secret"
            remove_secret_id_file_after_reading = false
        }
    }
    sink {
        type = "file"
        config = {
            path = "/run/consul_template.token"
            mode = 0600
        }
    }
}

vault {
    address = "https://${VAULT_SERVER_FQDN}"
}

listener "tcp" {
    address = "127.0.0.1:8100"
    tls_disable = true
}
EOF
chmod 444 /etc/vault-agent/config.hcl


# SKIPPING SOME CONFIG HERE FOR ROUTING ON MANAGEMENT NETWORK RULES


# Add container definitions to kubelet manifests
cat > /opt/kubelet/manifests/vault-agent.yml <<'EOF'
# Default config from ND-hypervisor image

apiVersion: v1
kind: Pod
metadata:
  name: vault-agent
  labels:
    role: vault-agent
spec:
  hostNetwork: true
  volumes:
    - name: vault-agent-config
      hostPath:
        path: /etc/vault-agent
    - name: certs
      hostPath:
        path: /etc/ssl/certs
    - name: run
      hostPath:
        path: /run
  containers:
    - name: vault-agent
      image: ${VAULT_REPO_PATH}/vault:${VAULT_AGENT_VERSION}
      command: ["vault"]
      args: ["agent", "-config", "/vault/config/config.hcl"]
      securityContext:
        capabilities:
          add:
            - IPC_LOCK
      volumeMounts:
        - mountPath: /vault/config
          name: vault-agent-config
        - mountPath: /etc/ssl/certs
          name: certs
        - mountPath: /run
          name: run
EOF
chmod 444 /opt/kubelet/manifests/vault-agent.yml


# Ansible doe snot include check on kubelet, and instead runs commands
# manually. We can include that here and bypass the whole role requiring
# only id and secret to come from somewhere. (insertable media? not secure tho)
