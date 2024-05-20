#!/bin/bash

set -e

# ROOTDIR=/tmps
ROOTDIR=/dev/shm

PYTHONBIN=/usr/bin/python3
# PYTHONBIN=/usr/local/bin/python3.9

export TORCHVISION_VERSION=0.8.1

cd $ROOTDIR
if [ ! -d vision ]; then
    git clone https://github.com/pytorch/vision.git -b v$TORCHVISION_VERSION
fi

cd vision
$PYTHONBIN setup.py bdist_wheel
sudo mkdir -p /home/.repository/pip
sudo cp dist/*.whl /home/.repository/pip

echo "#####################################"
echo " TorchVision build successfully. "
echo "#####################################"
