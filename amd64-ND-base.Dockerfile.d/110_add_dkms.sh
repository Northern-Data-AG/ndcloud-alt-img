#!/bin/sh -eu

. "$SRC/lib.sh"; init

chroot /target apt-get install -y \
  build-essential dkms \
  #
