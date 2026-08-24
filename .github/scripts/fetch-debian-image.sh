#!/usr/bin/env bash
# Download the base QCOW2 cloud image the profile is scanned against.
#
# Defaults to the official Debian 13 (trixie) "genericcloud" image published
# by the Debian cloud team. Unlike the SLES profile's openSUSE Leap stand-in,
# no substitute is needed here: Debian's own images are public, free, and
# require no registration, so CI scans the genuine target OS.
#
# The genericcloud image ships cloud-init but not the LXD agent, so the CI
# workflow bakes the Kitchen login user into the image offline with
# virt-customize rather than relying on LXD-delivered user-data.
#
# Optional env:
#   DEBIAN_IMAGE_URL -- full URL to a .qcow2 (default: latest trixie genericcloud amd64)
# Optional args:
#   $1 -- output path (default: debian-image.qcow2)

set -euo pipefail

DEFAULT_URL="https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2"
IMAGE_URL="${DEBIAN_IMAGE_URL:-$DEFAULT_URL}"
OUTPUT_FILE="${1:-debian-image.qcow2}"

echo "Downloading Debian image from: $IMAGE_URL"
curl -fL --retry 3 --retry-delay 5 -o "$OUTPUT_FILE" "$IMAGE_URL"

# Sanity check: make sure we actually got a QCOW2 and not an HTML error page.
if ! qemu-img info "$OUTPUT_FILE" >/dev/null 2>&1; then
  echo "Downloaded file is not a valid QCOW2 image. Check DEBIAN_IMAGE_URL." >&2
  exit 1
fi
echo "Saved Debian image to $OUTPUT_FILE"
