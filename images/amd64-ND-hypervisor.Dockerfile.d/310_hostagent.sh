#!/bin/sh -eu
PS4='> ${0##*/}: '
set -eu

. "$SRC/lib.sh"; init
set -x

# vars
CONTAINER_REGISTRY="harbor.tyr.taigacloud.tech"
HOSTAGENT_REPO_PATH="${CONTAINER_REGISTRY}/taiga"
HOSTAGENT_CONTAINER_TAG="latest@sha256:564f9d3484c8986872633f5874df41922caa9a049fa6122294a4ade7d93c47fc"
NAUTOBOT_URL="https://dcim.northerndata.tech/"
HOSTAGENT_NAUTOBOT_TOKEN="\${HOSTAGENT_NAUTOBOT_TOKEN}"
CLUSTER="\${CLUSTER}"
CLUSTER_UUID="\${CLUSTER_UUID}"
DEVICE_UUID="\${DEVICE_UUID}"
VXLAN_IP="\${VXLAN_IP}"
PURESTORAGE_PROXY_SECRET="\${PURESTORAGE_PROXY_SECRET}"
PURESTORAGE_PRIVATE_KEY_PASSWORD="\${PURESTORAGE_PRIVATE_KEY_PASSWORD}"
# NOTE: THIS IS MEH, need to configure to pull from our repo
# REPO mirror should allow to use cached mirrors, available for all
# node in the cluster

## builder doubts - still a bit confusing what is the /target and where the files are at
DST="${DST:-/target}"
if [ "$DST" = / ]; then
  DST=
fi


FSDIR="$0.d"

# use umask here
## Guarantee that at the least, files are protected from world
#old_umask="$(umask)"
#umask 007


# ==================== needs to be moved into its own hook ====================

# render_template SRC
#   Renders template SRC to stdout, substituting values from the environment.
#   Engine preference: gomplate (Go templates, e.g. {{ .Env.FOO }}),
#   then envsubst (e.g. ${FOO}). Override with TEMPLATE_ENGINE=gomplate|envsubst.
render_template() {
  _src="$1"
  _engine="${TEMPLATE_ENGINE:-}"

  if [ -z "$_engine" ]; then
    if command -v envsubst >/dev/null 2>&1; then
      _engine=envsubst
    else
      echo "render_template: envsubst found" >&2
      return 1
    fi
  fi

  case "$_engine" in
    envsubst) envsubst < "$_src" ;;
    *) echo "render_template: unknown engine '$_engine'" >&2; return 1 ;;
  esac
}

cd "$FSDIR"
find . ! -type d | \
  while read f; do
    case "$f" in
      */.placeholder ) continue ;;
    esac
    f="${f#./}"

    # destination name
    case "$f" in
      # drop .tmpl for templates
      *.tmpl ) out="${f%.tmpl}" ;;
      * )      out="$f" ;;
    esac

    # create destination directory tree
    d="$(dirname "${DST}/$out")"
    mkdir -p "$d"
    chmod 0755 "$d"

    # remove old file, if any
    rm -f "${DST}/$out"

    # render files into target image
    case "$f" in
      *.envsubst )
        cp -p "$f" "${DST}/$out"            # assign file the template's mode
        render_template "$f" > "${DST}/$out"
        rm -f "$f"
        ;;
      * )
        mv "$f" "${DST}/$out"
        ;;
    esac
  done

# ==================== needs to be moved into its own hook ====================

## reset umask
#umask "$old_umask"
