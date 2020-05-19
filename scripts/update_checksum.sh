#!/bin/bash
# 
# update_checksum.sh
#

set -exu -o pipefail

scriptdir=$(pwd)

update() {
    local pkg
    pkg=$1

    cd "$pkg"

    gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
}

if [ $1 == linux ]; then
    update "$scriptdir"/../linux
else
    for p in $(ls -d "$scriptdir"/../$1/*); do
        update $p &
    done
fi

wait
