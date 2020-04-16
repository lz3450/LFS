#!/bin/bash
# 
# base_build.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

scriptdir=$(pwd)
logdir="$scriptdir"/../log
pkgs=(
    base
    iana-etc
    linux-api-headers
    glibc
    tzdata
    gcc
    bash
    coreutils
    util-linux
    file
    findutils
    procps-ng
    psmisc
    shadow
    tar
    bzip2
    gzip
    xz
    grep
    sed
    gawk
    systemd
    pciutils
    iputils
    iproute2
    autoconf
    automake
    binutils
    bison
    fakeroot
    flex
    gettext
    libtool
    m4
    make
    meson
    ninja
    patch
    pkgconf
    sudo
    which
    perl
    python
    git
    pacman
)

if [[ -e $logdir ]]; then
    rm -rf $logdir
fi

mkdir -p $logdir

for p in ${pkgs[@]}
do
    echo $p
    log="$logdir"/$p.log
    cd "$scriptdir"/../base/$p
    # gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    makepkg --config "$scriptdir"/../config/makepkg-base.conf -cCf &>> $log
    sudo repo-add $LFS/pkgs/base/base.db.tar.gz $LFS/pkgs/base/$p-*.pkg.tar.gz &>> $log
done

sudo pacstrap -C ../config/pacman-lfs.conf /mnt/lfs base
