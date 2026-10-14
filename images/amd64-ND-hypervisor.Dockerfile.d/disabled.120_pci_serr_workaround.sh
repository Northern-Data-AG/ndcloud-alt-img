#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init

cd "$DST"


# Info on this
# https://northerndata.atlassian.net/wiki/spaces/IAAS/pages/2049146883/Gigabyte+PCIe+SERR+PERR+errors

# NOTES:
# dtomasgu 2026/10: This is a fix for GIGABYTE specific servers and
# may raize isolation problems on AMD systems. Also, GIGABYTE might
# have released a fix for this. This needs further testing and is
# because of that, disabled
apt install -y pciutils
systemctl enable pcie-serr-workaround.service
