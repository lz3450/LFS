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

WORKDIR=/tmp/cudnn
PKGNAME=cudnn-linux-x86_64-8.9.7.29_cuda12-archive.tar.xz

if [ ! -f "$HOME/Downloads/$PKGNAME" ]; then
    echo "Please download $PKGNAME from https://developer.nvidia.com/cudnn"
fi

sudo rm -rf "$WORKDIR"
mkdir -p "$WORKDIR"
tar -xf "$HOME/Downloads/$PKGNAME" -C "$WORKDIR"

sudo cp "$WORKDIR"/cudnn-*-archive/include/cudnn*.h /usr/local/cuda/include
sudo cp -P "$WORKDIR"/cudnn-*-archive/lib/libcudnn* /usr/local/cuda/lib64
sudo chmod a+r /usr/local/cuda/include/cudnn*.h /usr/local/cuda/lib64/libcudnn*
