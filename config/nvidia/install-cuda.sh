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

CUDA_VERSION=13.0.3

WORKDIR=/tmp/cuda
DOWNLOADS_DIR="$HOME/Downloads"
RUNFILE=cuda_13.0.3_580.126.20_linux.run

if [[ ! -f "$DOWNLOADS_DIR/$RUNFILE" ]]; then
    wget -P "$DOWNLOADS_DIR" https://developer.download.nvidia.com/compute/cuda/$CUDA_VERSION/local_installers/$RUNFILE
fi

sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
sudo bash "$DOWNLOADS_DIR/$RUNFILE" --tmpdir="$WORKDIR"

cp -v /var/log/cuda-installer.log cuda-install.log
