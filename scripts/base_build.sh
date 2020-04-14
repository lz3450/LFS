#!/bin/sh
# 
# base_build.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

builddir=$(pwd)
log="$builddir"/base.log
pkgs=(
    base
    linux-api-headers
    glibc
)

for p in ${pkgs[@]}
do
    echo ${p}
    cd "${builddir}"/${p}
    gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    makepkg --config ${builddir}/makepkg-core.conf -Cf &> $log
    sudo repo-add $LFS/pkgs/core/core.db.tar.gz $LFS/pkgs/core/${p}-*.pkg.tar.gz &> $log
done

sudo pacstrap -C ../config/pacman-lfs.conf /mnt/lfs base || exit
