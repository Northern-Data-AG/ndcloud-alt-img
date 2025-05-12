#!/bin/sh -eu

#- files in $0.d will be pupolualated to rootfs in /target
FSDIR="$0.d"
if [ -d "$FSDIR" ]; then
  . "/src/img-mangler.Dockerfile.d/100_add_files.sh"
else
  . "$SRC/lib.sh"; init
fi

chroot /target apt-get clean
chroot /target apt-get update

VER=575.51.03-1
chroot /target apt-get install --no-install-recommends -yd --allow-downgrades \
  nvidia-fabricmanager-${VER%%.*}=$VER \
  nvidia-kernel-dkms=$VER \
  firmware-nvidia-gsp=${VER%-[0-9]} \
  #

mkdir -p /target/srv/ci-installer/debs
mv /target/var/cache/apt/archives/*.deb /target/srv/ci-installer/debs
