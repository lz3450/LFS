#!/bin/bash
#
# install-cuda.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

CUDA_VERSION=12.6.3

WORKDIR=/tmp/cuda
DOWNLOADS_DIR="$HOME/Downloads"
RUNFILE=cuda_${CUDA_VERSION}_560.35.05_linux.run

source=https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/$RUNFILE

set -e

if [[ ! -f "$DOWNLOADS_DIR/$RUNFILE" ]]; then
    wget -P "$DOWNLOADS_DIR" https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/$RUNFILE
fi

sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
sudo bash "$DOWNLOADS_DIR/$RUNFILE" --tmpdir="$WORKDIR"
