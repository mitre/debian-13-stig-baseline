# Debian 13 overlay of the Canonical Ubuntu 24.04 LTS STIG baseline.
#
# All controls from the upstream profile are included as-is. Debian-specific
# adjustments (package names, file paths, N/A determinations for Ubuntu-only
# tooling) are made by overriding individual controls inside this block.
include_controls 'canonical-ubuntu-24.04-lts-stig-baseline'
