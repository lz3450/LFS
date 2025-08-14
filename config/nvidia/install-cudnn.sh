#!/bin/bash
#
# install-cudnn.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

################################################################################

# https://docs.nvidia.com/deeplearning/cudnn/installation/latest/linux.html#tarball-installation
# https://developer.download.nvidia.com/compute/cudnn/redist/

CUDNN_VERSION=9.12.0.46

WORKDIR=/tmp/cudnn
DOWNLOADS_DIR="$HOME/Downloads"
TARBALL=cudnn-linux-x86_64-${CUDNN_VERSION}_cuda12-archive.tar.xz
CUDNNDIR=$WORKDIR/cudnn-linux-x86_64-${CUDNN_VERSION}_cuda12-archive

if [[ ! -f "$DOWNLOADS_DIR/$TARBALL" ]]; then
    wget -P "$DOWNLOADS_DIR" https://developer.download.nvidia.com/compute/cudnn/redist/cudnn/linux-x86_64/$TARBALL
fi

sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
tar -xf "$HOME/Downloads/$TARBALL" -C "$WORKDIR"

sudo cp -vP "$CUDNNDIR"/include/* /usr/local/cuda/include/ > cudnn-install.log
sudo cp -vP "$CUDNNDIR"/lib/* /usr/local/cuda/lib64/ >> cudnn-install.log
