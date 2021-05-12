#!/bin/bash
#
# jetson-210.sh
#

set -e

l4t_dir="${ROOTDIR}/jetson-210/Linux_for_Tegra"
chroot_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

if [ ! -d ${ROOTDIR}/jetson-210 ]; then
    mkdir -p ${ROOTDIR}/jetson-210
    tar -xf ${ROOTDIR}/downloads/jetson-210_linux_r32.5.1_aarch64.tbz2 -C ${ROOTDIR}/jetson-210
fi

pushd "${l4t_dir}" > /dev/null 2>&1

sudo rm -rf rootfs/*

pushd rootfs > /dev/null 2>&1
sudo tar -xpf ${ROOTDIR}/mksamplefs/sample_fs.tbz2
popd > /dev/null

sudo PATH="${chroot_path}" ./apply_binaries.sh

pushd tools > /dev/null 2>&1
sudo ./jetson-disk-image-creator.sh -o ${l4t_dir}/sd_blob.img -b jetson-nano-2gb-devkit
popd > /dev/null

popd > /dev/null