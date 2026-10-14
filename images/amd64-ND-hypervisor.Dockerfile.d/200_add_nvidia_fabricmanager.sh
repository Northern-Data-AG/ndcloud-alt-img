#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars
NVIDIA_DRIVER_PRODUCTION_BRANCH="595"

cd "$DST"


# We need to figure out how to move files from dir structure.
##- files in $0.d will be pupolualated to rootfs in /target
#FSDIR="$0.d"
#if [ -d "$FSDIR" ]; then
#  . "/src/img-mangler.Dockerfile.d/100_add_files.sh"
#else
#  . "$SRC/lib.sh"; init
#fi


# add nvidia cuda repo sources and keys
# dump key for cuda apt repo ?? maybe needs update? prob old
echo -n "mQINBGifVE8BEAC93Cb4eItzcGtiuMHka7LfZiUJctF6LiwOG/gGbZeHzN8/pGg/62Ttxy0xEWl7AChtmQfH5b1+SvlMs0ZciN0E2LURantgw8sH+4v8f1cEa0/zEGerzmNFlpdjPShvkPhD3bVchreN+D0mK/jhhk8DjJtgZTn2DsAaKq73hVLldM2YSFO3n/5zgeqhTnUY0C1z+2ovMr5FCtRSRFzxl6Qx3XezWjMzqwJx+xhpZ0cqXMgMt0Pof3VH7FuQyWu97HbhaZJVVBzlqyg30xrMpeDv3R4bjwY0whacbP/ZNxCXtkqgItQ02L7to+3doNdIZPJ8rReM5UAQfa3rEjUPEdBn3QnkvGFOvv0IXXDqtp5jQhYC6dEAnxj1Qkcb5bCK1G9g6OB5Evc1ts9uW1+jr8JP8l/YYNepBCbIXauuYTj2f98dO2FykLfuGQ7ELne4vCpI2+5Vp4JqnynJPA0KevA7jc3HWE0shPMgEa/Cxi2O2bNf0qdhQYTlXFJJVYigd4aTnDlFT4pmrIyX5rseTKCADkqgOagZbOJXLt2K2m0sQVNTVwfPpjEYvJroFTFPPzYk3n4dIJfItS5H5DE8TLa1x4fwZFlM9XaPHbJg5GLN0VyBWrtccXdG9/B/iIoEUjNuEIEnT+E9z6s1Bqfj3NzCMJXO1v/LWm9TntrRzgKFrQARAQABtDFLaXRtYWtlciAoRGViaWFuIDEzIFRyaXhpZSkgPGtpdG1ha2VyQG52aWRpYS5jb20+iQJFBBMBCAAvFiEEAhguYBBPzcJurhuFl6XUy4eT8gAFAmifVE8CGy8CCwkCFQoCFgICHgUCF4AACgkQl6XUy4eT8gBf+A/9EoZKaWNS0mbO5iV1XFnhqGqS0RbHu2VXGF5lNHzPy2ukmivaOYhnCg3WCXzUPvhNsAkyVB2WXawMvbGlU1qk+vUSF+mXKC+trh8eR9H6nCzsfLRo3+I7n5iMOiYxNv94jHS+hZqtOA8iKDLkUfCyHnRcSCpuaEzhT1hOysp/XTMzCCEvoEyIqJxcjCtCck59NIpd4ulXYMTse5SM+LPPujtzNJp99ujcVpHS4Tmk+RXHKpAk4yQtHNeY6TesezHZ+3TmYcGSxgGrkM9RjmZShLOxARNmq+X1Z+lgCe/Mj9KgMaUfmHSL/vn69bV6Q1dmYV5z+Gr9Ib7KLXFmlhxucL0hUb9F4hH7QC1EJY9zoGY/RRZ840/ZnQaAiF73Sr332h8vsQIm2I8KmHZ+1u06e9v28yOKdvcwZYoEmvtic23SMVcntCZCKqLqlR1ory87bpxpXKSmaGgQIAP+jsv0kT+HRJHQ/nOJLwFZAqfJKWnY9REdO7Cy/7UOefnTbNV7yzEEp+AZq7CnEY7u6EzIIbjxt6g5QjV1wcCOBVXkgWaY2KmxiZyJVDtf+alqO78PDXdMnDRdK0pqFPrx0bLGNL4Yn9Hc/SvufXeI/tJr9RNMrjBvG0C1VVZh7ZIiMsXkd07setQEG1Y65/GEEDJlrSUZqQZRQjv1MaBElWAR6xQ=" | base64 -d > /etc/apt/keyrings/cuda-archive-keyring.gpg
chmod 644 /etc/apt/keyrings/cuda-archive-keyring.gpg

# add sources file, will need to also have a mirror at ND. and set APT
# priorities
# if we install repo key with deb package, the file is a list file and the key
# is under /usr/share/key
cat > /etc/apt/sources.list.d/cuda.sources <<EOF
# Default config from ND-hypervisor image

Types: deb
URIs: https://developer.download.nvidia.com/compute/cuda/repos/debian$(. /etc/os-release && echo "$VERSION_ID")/$(uname -m)/
Suites: /
Signed-By: /etc/apt/keyrings/cuda-archive-keyring.gpg
EOF
chmod 444 /etc/apt/sources.list.d/cuda.sources


# update and install nvswitch control dependencies
apt update
# missing kernel headers???? linux-headers-7.0.0-31-generic
apt install -y --no-install-recommends \
  firmware-nvidia-gsp=${NVIDIA_DRIVER_PRODUCTION_BRANCH}.* \
  nvidia-kernel-dkms=${NVIDIA_DRIVER_PRODUCTION_BRANCH}.* \
  nvidia-fabricmanager=${NVIDIA_DRIVER_PRODUCTION_BRANCH}.*


mkdir -p /etc/nvidia-fabricmanager
chmod 755 /etc/nvidia-fabricmanager


# include quake hypervisor fabricmanager configuration file
cat > /etc/nvidia-fabricmanager/fabricmanager.cfg <<EOF
# Default config from ND-hypervisor image

# NVIDIA Fabric Manager configuration file.
# Note: This configuration file is read during Fabric Manager service startup. So, Fabric Manager
# service restart is required for new settings to take effect.

#	Description: Fabric Manager logging levels
#	Possible Values:
#		0  - All the logging is disabled
#		1  - Set log level to CRITICAL and above
#		2  - Set log level to ERROR and above
#		3  - Set log level to WARNING and above
#		4  - Set log level to INFO and above
LOG_LEVEL=4

#	Description: Filename for Fabric Manager logs
#	Possible Values:
#       Full path/filename string (max length of 256). Logs will be redirected to console(stderr)
#       if the specified log file can't be opened or the path is empty.
LOG_FILE_NAME=/var/log/fabricmanager.log

#	Description: Append to an existing log file or overwrite the logs
#	Possible Values:
#		0  - No  (Log file will be overwritten)
#		1  - Yes (Append to existing log)
LOG_APPEND_TO_LOG=1

#	Description: Max size of log file (in MB)
#	Possible Values:
#		Any Integer values
LOG_FILE_MAX_SIZE=1024

#   Description: Number of times the FM log is rotated once it reaches LOG_FILE_MAX_SIZE
#   Possible Values:
#       0                - Log is not rotated. Logging is stopped once the FM log file reaches
#                          the size specified in LOG_FILE_MAX_SIZE
#       Non-zero Integer - Log is rotated upto the number of times specified in LOG_MAX_ROTATE_COUNT,
#                          after the size of the log file reaches the size specified in LOG_FILE_MAX_SIZE.
#                          Combined FM log size is LOG_FILE_MAX_SIZE multipled by LOG_MAX_ROTATE_COUNT+1
#                          Once this threshold is reached, the oldest log file is purged and reused.
LOG_MAX_ROTATE_COUNT=3

#	Description: Redirect all the logs to syslog instead of logging to file
#	Possible Values:
#		0  - No
#		1  - Yes
LOG_USE_SYSLOG=0

#	Description: daemonize Fabric Manager on start-up
#	Possible Values:
#       0  - No (Do not daemonize and run fabric manager as a normal process)
#       1  - Yes (Run Fabric Manager process as Unix daemon
DAEMONIZE=1

#	Description: Network interface to listen for Global and Local Fabric Manager communication
#	Possible Values:
#		A valid IPv4 address. By default, uses loopback (127.0.0.1) interface
#   Note: This is only effective on DGX A100, HGX A100, DGX H100, HGX H100 NVSwitch based systems
BIND_INTERFACE_IP=127.0.0.1

#	Description: Starting TCP port number for Global and Local Fabric Manager communication
#	Possible Values:
#		Any value between 0 and 65535
#   Note: This is only effective on DGX A100, HGX A100, DGX H100, HGX H100 NVSwitch based systems
STARTING_TCP_PORT=16000

#   Description: Use Unix sockets instead of TCP Socket for Global and Local Fabric Manager communication
#	Possible Values:
#		Unix domain socket path (max length of 256)
#	Default Value:
#		Empty String (TCP socket will be used instead of Unix sockets)
#   Note: This is only effective on DGX A100, HGX A100, DGX H100, HGX H100 NVSwitch based systems
UNIX_SOCKET_PATH=

#	Description: Fabric Manager Operating Mode
#	Possible Values:
#       0  - Start Fabric Manager in Bare metal or Full pass through virtualization mode
#       1  - Start Fabric Manager in Shared NVSwitch multitenancy mode.
#       2  - Start Fabric Manager in vGPU based multitenancy mode.
FABRIC_MODE=1

#	Description: Restart Fabric Manager after exit
#                On DGX A100, HGX A100, DGX H100, HGX H100 NVSwitch based systems, this is applicable only in Shared
#                NVSwitch or vGPU based multitenancy mode
#	Possible Values:
#       0  - Start Fabric Manager and follow full initialization sequence
#       1  - Start Fabric Manager and follow resiliency/restart sequence
FABRIC_MODE_RESTART=0

#	Description: Specify the filename to be used to save Fabric Manager states.
#                    Valid only if Shared NVSwitch or vGPU based multitenancy mode is enabled
#	Possible Values:
#	    Full path/filename string (max length of 256)
#   Note: This is only effective on DGX A100, HGX A100, DGX H100, HGX H100 NVSwitch based systems
STATE_FILE_NAME=/run/nvidia-fabricmanager/fabricmanager.state

#	Description: Network interface to listen for Fabric Manager SDK/API to communicate with running FM instance.
#	Possible Values:
#		A valid IPv4 address. By default, uses loopback (127.0.0.1) interface
FM_CMD_BIND_INTERFACE=127.0.0.1

#	Description: TCP port number for Fabric Manager SDK/API to communicate with running FM instance.
#	Possible Values:
#		Any value between 0 and 65535
FM_CMD_PORT_NUMBER=6666

#	Description: Use Unix sockets instead of TCP Socket for Fabric Manager SDK/API communication
#	Possible Values:
#		Unix domain socket path (max length of 256)
#	Default Value:
#		Empty String (TCP socket will be used instead of Unix sockets)
FM_CMD_UNIX_SOCKET_PATH=

#   Description: Fabric Manager does not exit when facing failures
#   Possible Values:
#       0 – Fabric Manager service will terminate on errors such as, NVSwitch and GPU config failure,
#           typical software errors etc.
#       1 – Fabric Manager service will stay running on errors such as, NVSwitch and GPU config failure,
#           typical software errors etc. However, the system will be uninitialized and CUDA application
#           launch will fail.
FM_STAY_RESIDENT_ON_FAILURES=0

#   Description: Degraded Mode options when there is an Access Link Failure (GPU to NVSwitch NVLink failure)
#   Possible Values:
#       In bare metal or full passthrough virtualization mode
#       0  - Remove the GPU with the Access NVLink failure from NVLink P2P capability
#       1  - Disable the NVSwitch and its peer NVSwitch, which reduces NVLink P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#
#       In Shared NVSwitch or vGPU based multitenancy mode
#       0  - Disable partitions which are using the Access Link failed GPU
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#       1  - Disable the NVSwitch and its peer NVSwitch,
#            all partitions will be available but with reduced NVLink P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
ACCESS_LINK_FAILURE_MODE=0

#   Description: Degraded Mode options when there is a Trunk Link Failure (NVSwitch to NVSwitch NVLink failure)
#   Possible Values:
#       In bare metal or full passthrough virtualization mode
#       0  - Exit Fabric Manager and leave the system/NVLinks uninitialized
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#       1  - Disable the NVSwitch and its peer NVSwitch, which reduces NVLink P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#
#       In Shared NVSwitch or vGPU based multitenancy mode
#       0  - Remove partitions that are using the Trunk NVLinks
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#       1  - Disable the NVSwitch and its peer NVSwitch,
#            all partitions will be available but with reduced NVLink P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
TRUNK_LINK_FAILURE_MODE=0

#   Description: Degraded Mode options when there is a NVSwitch failure or an NVSwitch is excluded
#   Possible Values:
#       In bare metal or full passthrough virtualization mode
#       0  - Abort Fabric Manager
#       1  - Disable the NVSwitch and its peer NVSwitch, which reduces P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#
#       In Shared NVSwitch or vGPU based multitenancy mode
#       0  - Disable partitions that are using the NVSwitch
#            This is only effective on DGX A100 and HGX A100 NVSwitch based systems
#       1  - Disable the NVSwitch and its peer NVSwitch,
#            all partitions will be available but with reduced NVLink P2P bandwidth
#            Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
NVSWITCH_FAILURE_MODE=0

#	Description: Control running CUDA jobs behavior when Fabric Manager service is stopped or terminated
#	Possible Values:
#       0  - Do not abort running CUDA jobs when Fabric Manager exits. However new CUDA job launch will fail.
#       1  - Abort all running CUDA jobs when Fabric Manager exits.
#	Note: This is only effective on DGX A100 and HGX A100 NVSwitch based systems
ABORT_CUDA_JOBS_ON_FM_EXIT=1

#       Description: Absolute directory path containing Fabric Manager topology files
#       Possible Values:
#               A valid directory path string (max length of 256)
TOPOLOGY_FILE_PATH=/usr/share/nvidia/nvswitch

#   Description: Use RPC instead of raw sockets for communication between global and local fabric manager.
#   Possible values:
#       0 - Do not use RPCs
#       1 - Use RPC
USE_RPC=1

#  Description: Name of the network interface used for communication.
#               OPTIONAL - If empty, network interface will be determined by matching bind IP to
#                          node configuration file.  Only necessary to configure if the bind IP
#                          is present on multiple network interfaces.
#  Possible Values:
#      Interface names like eth0, ens32 .. etc
#  Default Value:
NETWORK_INTERFACE=


#  Description:  Enable authentication and encryption for RPC communication.
#                NOTE: If USE_RPC is 0, this is ignored.
#  Possible Values:
#      0:  Disable encryption and authentication
#      1:  Enable encryption and authentication
#  Default value: 0
ENABLE_AUTH_ENCRYPTION=0

#  Description:  This determines how fabric manager will try to retrieve the keys, certificates, and certificate
#                authority for authentication and encryption.
#                If ENABLE_AUTH_ENCRYPTION is enabled (1), then AUTH_SOURCE must be configured
#                as one of the supported values.  An empty or unexpected value will prevent initialization.
#                If USE_RPC is 0, this is ignored.
#  Possible Values:
#      FILE:      The provided values are paths to files on the file system.
#      ENV_PATH:  The provided values are environment variable names to retrieve, and the values in the
#                 environment variables are treated as paths to files on the file system.
#      ENV_VAL:   The provided values are environment variable names to retrieve, and the values in the
#                 environment variables are treated as the actual values for the key/cert/cert auth.
AUTH_SOURCE=

# Description:  These fields are interpreted based on how AUTH_SOURCE is configured
SERVER_KEY=
SERVER_CERT=
SERVER_CERT_AUTH=
CLIENT_KEY=
CLIENT_CERT=
CLIENT_CERT_AUTH=

#  Description:  Override the target hostname for authentication of the certificates and keys.  This allows
#                certificates with common names that do not match the ip addresses provided for the nodes.
#                Example:
#                  If the certificate has the subject:
#                    "/C=US/ST=CA/L=Santa Clara/O=NVIDIA/OU=Test/CN=localhost"
#                  The certificate validation will expect the connection hostname to be "localhost", by
#                  setting IMEX_SECURITY_TARGET_OVERRIDE=localhost you can cause override the connection
#                  hostname for security purposes to be "localhost", allowing the connection to succeed.
#                If USE_RPC is 0, this is ignored.
SECURITY_TARGET_OVERRIDE=

#  Description: This tunable determines the domain behavior in case the trunk links are down or experience
#               fatal errors. When MNNVL_RESILIENCY_MODE is set to 0, in case a single trunk link fails, the
#               inter-node traffic between the impacted L1 switch node and the rest of the domain will be
#               unavailable. When MNNVL_RESILIENCY_MODE is set to 1, the domain can sustain up to failures
#               of half (excluded) of the trunk links on an L1 switch before the inter-node traffic between
#               this L1 switch node and the rest of the domain becomes unavailable.
MNNVL_RESILIENCY_MODE=0

#	Description: Determine whether a default partition needs to be created
#	Possible Values:
#       0             - No partitions are created during GFM initialization. GFM disables routing until an API request
#                     to create a partition is successful.
#       1(default)    - Creates a default partition during GFM initialization. GFM creates the partition to include
#                     all GPUs in the topology and enables routing so that all GPUs can communicate to each other.

MNNVL_ENABLE_DEFAULT_PARTITION=1
EOF
chmod 444 /etc/nvidia-fabricmanager/fabricmanager.cfg


cat > /etc/systemd/system/nvidia-fabricmanager.service <<EOF
# Default config from ND-hypervisor image

[Unit]
Description=NVIDIA fabric manager service
ConditionPathExists=/dev/nvidia-nvswitchctl
After=network-online.target
Requires=network-online.target

[Service]
User=root
PrivateTmp=false
Type=forking
TimeoutStartSec=720

Environment="FM_CONFIG_FILE=/etc/nvidia-fabricmanager/fabricmanager.cfg"
Environment="FM_PID_FILE=/run/nvidia-fabricmanager/nv-fabricmanager.pid"
Environment="NVLSM_CONFIG_FILE=/etc/nvidia-fabricmanager/nvlsm.conf"
Environment="NVLSM_PID_FILE=/run/nvidia-fabricmanager/nvlsm.pid"

PIDFile=/run/nvidia-fabricmanager/nv-fabricmanager.pid

ExecStart=/usr/bin/nvidia-fabricmanager-start.sh --mode start
ExecStartPost=/usr/sbin/modprobe -r nvidia_drm nvidia_modeset
ExecStop=/usr/bin/nvidia-fabricmanager-start.sh --mode stop
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF
chmod 444 /etc/systemd/system/nvidia-fabricmanager.service
systemctl enable nvidia-fabricmanager.service

