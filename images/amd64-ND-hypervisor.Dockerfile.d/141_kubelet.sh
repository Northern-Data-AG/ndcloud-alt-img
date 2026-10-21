#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

# versions
KUBELET_VERSION="v1.24.17"
# binaries
# https://dl.k8s.io/<semver>/bin/linux/<arch>/kubelet
PKG="http://tmp.iso-server.hydro66.northerndata.tech/ansible/${KUBELET_VERSION}/amd64/kubelet"

cd "$DST"

PKG="${PKG##*/}"


mkdir -p /etc/kubelet
mkdir -p /opt/kubelet/manifests
chmod 755 -R /etc/kubelet
chmod 755 -R /opt/kubelet

# install kubelet
sudo install -o root -g root -m 0755 kubelet /opt/kubelet/kubelet_${KUBELET_VERSION}


# ship kubelet configuration
cat > /etc/kubelet/config.yml <<'EOF'
# Default config from ND-hypervisor image

apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
enableServer: true
staticPodPath: "/opt/kubelet/manifests"
syncFrequency: 1m0s
fileCheckFrequency: 20s
httpCheckFrequency: 20s
address: "::1"
port: 10250
readOnlyPort: 10255
authentication:
  x509: {}
  webhook:
    enabled: false
    cacheTTL: 2m0s
  anonymous:
    enabled: true
authorization:
  mode: AlwaysAllow
  webhook:
    cacheAuthorizedTTL: 5m0s
    cacheUnauthorizedTTL: 30s
registryPullQPS: 5
registryBurst: 10
eventRecordQPS: 5
eventBurst: 10
enableDebuggingHandlers: true
healthzPort: 10248
healthzBindAddress: "::1"
oomScoreAdj: -999
streamingConnectionIdleTimeout: 4h0m0s
nodeStatusUpdateFrequency: 10s
nodeStatusReportFrequency: 5m0s
nodeLeaseDurationSeconds: 40
imageMinimumGCAge: 2m0s
imageGCHighThresholdPercent: 85
imageGCLowThresholdPercent: 80
volumeStatsAggPeriod: 1m0s
cgroupsPerQOS: true
cgroupDriver: systemd
cpuManagerPolicy: none
cpuManagerReconcilePeriod: 10s
memoryManagerPolicy: None
topologyManagerPolicy: none
topologyManagerScope: container
runtimeRequestTimeout: 2m0s
hairpinMode: promiscuous-bridge
maxPods: 110
podPidsLimit: -1
resolvConf: "/etc/resolv.conf"
cpuCFSQuota: true
cpuCFSQuotaPeriod: 100ms
nodeStatusMaxImages: 50
maxOpenFiles: 1000000
contentType: application/vnd.kubernetes.protobuf
kubeAPIQPS: 5
kubeAPIBurst: 10
serializeImagePulls: true
evictionHard:
  imagefs.available: 15%
  memory.available: 100Mi
  nodefs.available: 10%
  nodefs.inodesFree: 5%
evictionPressureTransitionPeriod: 5m0s
enableControllerAttachDetach: true
makeIPTablesUtilChains: false
iptablesMasqueradeBit: 14
iptablesDropBit: 15
failSwapOn: true
memorySwap: {}
containerLogMaxSize: 25Mi
containerLogMaxFiles: 5
configMapAndSecretChangeDetectionStrategy: Watch
enforceNodeAllocatable:
- pods
logging:
  format: text
  flushFrequency: 5000000000
  verbosity: 0
  options:
    json:
      infoBufferSize: '0'
enableSystemLogHandler: true
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
enableProfilingHandler: true
enableDebugFlagsHandler: true
seccompDefault: false
memoryThrottlingFactor: 0.8
registerNode: true
EOF
chmod 444 /etc/kubelet/config.yml


# ship kubelet systemd unit
cat > /etc/systemd/system/kubelet.service <<EOF
# Default config from ND-hypervisor image

[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/kubernetes/kubernetes
After=containerd.service
Requires=containerd.service
StartLimitBurst=5
StartLimitIntervalSec=60

[Service]
ExecStart=/opt/kubelet/kubelet_${KUBELET_VERSION} \
    --container-runtime remote \
    --container-runtime-endpoint unix:///run/containerd/containerd.sock \
    --node-ip "::" \
    --config /etc/kubelet/config.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
chmod 444 /etc/systemd/system/kubelet.service
systemctl enable kubelet.service
