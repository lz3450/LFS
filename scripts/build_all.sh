#!/bin/bash
# 
# build_all.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

scriptdir=$(pwd)
logdir="$scriptdir"/../log

build() {
    log="$logdir"/$2.log
    if [[ -f $log ]]; then
        rm $log
    fi
    cd "$scriptdir"/../$1/$2
    # gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
    makepkg --config "$scriptdir"/../config/makepkg-lfs.conf -scCLf &>> $log
}

case $1 in
    core)
        pkgs=${core_pkgs[@]}
        repo='core'
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

if [[ ! -d $logdir ]]; then
    mkdir -p $logdir
fi

for p in $(ls --format=single-column ../$repo); do
    build $repo $p
done
