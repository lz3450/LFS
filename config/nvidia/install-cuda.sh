#!/bin/bash
#
# install-cuda.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

################################################################################

# https://developer.nvidia.com/cuda-toolkit-archive

CUDA_VERSION=12.8.1

WORKDIR=/tmp/cuda
DOWNLOADS_DIR="$HOME/Downloads"
RUNFILE=cuda_${CUDA_VERSION}_570.124.06_linux.run

if [[ ! -f "$DOWNLOADS_DIR/$RUNFILE" ]]; then
    wget -P "$DOWNLOADS_DIR" https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/$RUNFILE
fi

sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
sudo bash "$DOWNLOADS_DIR/$RUNFILE" --tmpdir="$WORKDIR"
