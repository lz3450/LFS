#!/bin/bash

set -e

ROOTDIR=/tmp

TORCHVISION_VERSION=0.7.0

# torchvision
cd $ROOTDIR
git clone https://github.com/pytorch/vision.git -b v$TORCHVISION_VERSION
cd vision

python setup.py build
sudo python setup.py install

echo "#####################################"
echo " TorchVision installed successfully. "
echo "#####################################"
