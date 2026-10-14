#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars

cd "$DST"


# This is mostly config and host/site dependent, so not here
