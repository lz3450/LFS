#!/bin/bash
#
# initialize.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
# SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

# unset __DEBUG__
# __DEBUG__=1

### functions
usr_pip() {
    local _pkgs="$@"

    python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: ${_pkgs[@]}
    python3 -m pip install --user -U --no-index --find-links ~/wheels ${_pkgs[@]}
}

opt_pip() {
    local _pkgs="$@"

    /opt/bin/python3 -m pip wheel --wheel-dir ~/wheels --no-binary :all: ${_pkgs[@]}
    /opt/bin/python3 -m pip install --user -U --no-index --find-links ~/wheels ${_pkgs[@]}
}

################################################################################

sudo apt-get update
sudo apt-get upgrade --no-install-recommends -y
sudo apt-get install --no-install-recommends -y python3-pip

usr_pip wheel setuptools
usr_pip pip
usr_pip meson ninja