#!/bin/bash
# 
# build.sh
#

set -exu -o pipefail

scriptdir=$(pwd)

build() {
    local pkg
    pkg=$1

    cd $pkg

    local log
    log=build.log
    if [[ -f $log ]]; then
        rm $log
    fi

    gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
    makepkg -scCf --nocheck --noconfirm &>> $log
}

case $1 in
    linux)
        pkgs="$scriptdir"/../linux
        ;;
    core)
        pkgs=$(find $scriptdir/../core/* -type d -name "[s-z]*")
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

for p in ${pkgs[@]}; do
    build $p
done
