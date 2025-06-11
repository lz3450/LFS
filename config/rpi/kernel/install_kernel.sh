#!/bin/sh

sudo apt purge \
    raspberrypi-kernel \
    raspberrypi-kernel-headers \

sudo cp -rf kernel_install/* /
