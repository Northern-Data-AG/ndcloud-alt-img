#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars

cd "$DST"


# install libvirt dependencies
apt install -y \
  dnsmasq \
  bridge-utils \
  lz4 \
  gdisk \
  #


# install host system guest manager and virtualization
# --no-install-recommends makes something miss relative to tls and nothing
# works
apt install -y \
  ovmf \
  qemu-system qemu-system-x86 qemu-utils \
  libvirt-daemon-system libvirt-clients \
  libguestfs-tools \
  #


# setup services
systemctl disable dndsmasq.service
systemctl enable libvirtd.service


# assure and manage groups for ndhpc user
for g in libvirt video plugdev kvm; do
    getent group "$g" >/dev/null || groupadd -r "$g"
done

if id ndhpc >/dev/null 2>&1; then
    usermod -c "Northern Data HPC Host user" -s /bin/bash -a -G libvirt,video,plugdev,kvm ndhpc
else
    useradd -m -c "Northern Data HPC Host user" -s /bin/bash -G libvirt,video,plugdev,kvm ndhpc
fi


# create path for guest storage pools and create them
## UUIDs can be the same as they may collide outside of node scope
## Also, if the pools are shared by the hosts, it's advantageous they are the same
libvirtd --daemon
mkdir -p /etc/libvirt/storage/autostart
for d in cloudinit hdds isos; do
  mkdir -p /var/lib/libvirt/images/${d}
  chmod 711 /var/lib/libvirt/images/${d} # prev 744
  # libvirt.sock is not available. Start it
  virsh pool-define-as ${d} dir --target /var/lib/libvirt/images/${d}/${d}.xml
  virsh pool-autostart ${d}
done
kill $(pgrep libvirtd)


# add userspace policy kit rules
mkdir -p /etc/polkit-1/rules.d
chmod 755 /etc/polkit-1/rules.d

cat > /etc/polkit-1/rules.d/10-consoleagent.rules <<'EOF'
# Default config from ND-hypervisor image

polkit.addRule(function(action, subject) {
    if (action.id == "org.libvirt.unix.monitor" &&
        subject.isInGroup("consoleagent")) {
        /* Give the system group consoleagent read-only access to libvirt (monitor instead of manage) */
        return "yes";
    }
});
EOF
chmod 444 /etc/polkit-1/rules.d/10-consoleagent.rules


## add edk2??
#mkdir -p /opt/edk2
#chmod 555 /opt/edk2
# In this step, ansible installs edk2 but we already have it with OVMF, so..
# is it needed???


# grant ptrace-permissions for libvirtd and containerd in apparmor
cat > /etc/apparmor.d/usr.sbin.libvirtd <<'EOF'
# Default config from ND-hypervisor image

#include <tunables/global>
@{LIBVIRT}="libvirt"

profile libvirtd /usr/sbin/libvirtd flags=(attach_disconnected) {
  #include <abstractions/base>
  #include <abstractions/dbus>

  capability kill,
  capability net_admin,
  capability net_raw,
  capability setgid,
  capability sys_admin,
  capability sys_module,
  capability sys_ptrace,
  capability sys_pacct,
  capability sys_nice,
  capability sys_chroot,
  capability setuid,
  capability dac_override,
  capability dac_read_search,
  capability fowner,
  capability chown,
  capability setpcap,
  capability mknod,
  capability fsetid,
  capability audit_write,
  capability ipc_lock,
  capability sys_rawio,
  capability bpf,
  capability perfmon,

  # Needed for vfio
  capability sys_resource,

  mount options=(rw,rslave)  -> /,
  mount options=(rw, nosuid) -> /{var/,}run/libvirt/qemu/*.dev/,
  umount /{var/,}run/libvirt/qemu/*.dev/,
  umount /dev/,

  # libvirt provides any mounts under /dev to qemu namespaces
  mount options=(rw, move) /dev/ -> /{,var/}run/libvirt/qemu/*.dev/,
  mount options=(rw, move) /dev/** -> /{,var/}run/libvirt/qemu/*{,/},
  mount options=(rw, move) /{,var/}run/libvirt/qemu/*.dev/ -> /dev/,
  mount options=(rw, move) /{,var/}run/libvirt/qemu/*{,/} -> /dev/**,

  network inet stream,
  network inet dgram,
  network inet6 stream,
  network inet6 dgram,
  network netlink raw,
  network packet dgram,
  network packet raw,

  # for --p2p migrations
  unix (send, receive) type=stream addr=none peer=(label=unconfined addr=none),

  ptrace (read,trace) peer=unconfined,
  ptrace (read,trace) peer=@{profile_name},
  ptrace (read,trace) peer=dnsmasq,
  ptrace (read,trace) peer=/usr/sbin/dnsmasq,
  ptrace (read,trace) peer=libvirt-*,
  ptrace (read,trace) peer=swtpm,
  ptrace (read,trace) peer=cri-containerd*,

  signal (send) peer=dnsmasq,
  signal (send) peer=/usr/sbin/dnsmasq,
  signal (read, send) peer=libvirt-*,
  signal (send) set=("kill", "term") peer=unconfined,

  # For communication/control to qemu-bridge-helper
  unix (send, receive) type=stream addr=none peer=(label=libvirtd//qemu_bridge_helper),
  signal (send) set=("term") peer=libvirtd//qemu_bridge_helper,

  # allow connect with openGraphicsFD, direction reversed in newer versions
  unix (send, receive) type=stream addr=none peer=(label=libvirt-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*),
  # unconfined also required if guests run without security module
  unix (send, receive) type=stream addr=none peer=(label=unconfined),

  # required if guests run unconfined seclabel type='none' but libvirtd is confined
  signal (read, send) peer=unconfined,

  # Very lenient profile for libvirtd since we want to first focus on confining
  # the guests. Guests will have a very restricted profile.
  / r,
  /** rwmkl,

  /bin/* PUx,
  /sbin/* PUx,
  /usr/bin/* PUx,
  /usr/sbin/virtlogd pix,
  /usr/sbin/* PUx,
  /{usr/,}lib/udev/scsi_id PUx,
  /usr/{lib,lib64}/xen-common/bin/xen-toolstack PUx,
  /usr/{lib,lib64,libexec}/xen/bin/* Ux,
  /usr/{lib,libexec}/xen-*/bin/libxl-save-helper PUx,
  /usr/{lib,libexec}/xen-*/bin/pygrub PUx,
  /usr/{lib,lib64,lib/qemu,libexec}/vhost-user-gpu PUx,
  /usr/{lib,lib64,lib/qemu,libexec}/virtiofsd PUx,

  # Required by nwfilter_ebiptables_driver.c:ebiptablesWriteToTempFile() to
  # read and run an ebtables script.
  /var/lib/libvirt/virtd* ixr,

  # force the use of virt-aa-helper
  audit deny /{usr/,}sbin/apparmor_parser rwxl,
  audit deny /etc/apparmor.d/libvirt/** wxl,
  audit deny /sys/kernel/security/apparmor/features rwxl,
  audit deny /sys/kernel/security/apparmor/matching rwxl,
  audit deny /sys/kernel/security/apparmor/.* rwxl,
  /sys/kernel/security/apparmor/profiles r,
  /usr/lib/libvirt/* PUxr,
  /usr/lib/libvirt/libvirt_parthelper ix,
  /usr/lib/libvirt/libvirt_iohelper ix,
  /etc/libvirt/hooks/** rmix,
  /etc/xen/scripts/** rmix,

  # allow changing to our UUID-based named profiles
  change_profile -> @{LIBVIRT}-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*-[0-9a-f]*,

  /usr/{lib,lib64,lib/qemu,libexec}/qemu-bridge-helper Cx -> qemu_bridge_helper,
  # child profile for bridge helper process
  profile qemu_bridge_helper {
    #include <abstractions/base>

    capability setuid,
    capability setgid,
    capability setpcap,
    capability net_admin,

    network inet stream,

    # For communication/control from libvirtd
    unix (send, receive) type=stream addr=none peer=(label=libvirtd),
    signal (receive) set=("term") peer=/usr/sbin/libvirtd,
    signal (receive) set=("term") peer=libvirtd,

    /dev/net/tun rw,
    /etc/qemu/** r,
    owner @{PROC}/*/status r,

    /usr/{lib,lib64,lib/qemu,libexec}/qemu-bridge-helper rmix,
  }

  # Site-specific additions and overrides. See local/README for details.
  #include <local/usr.sbin.libvirtd>
}
EOF
chmod 644 /etc/apparmor.d/usr.sbin.libvirtd
