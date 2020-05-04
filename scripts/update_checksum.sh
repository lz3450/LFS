#!/bin/bash
# 
# update_checksum.sh
#

set -exu -o pipefail

scriptdir=$(pwd)

update() {
    local pkg
    pkg=$1

    cd "$scriptdir"/../$repo/$pkg

    gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
}

repo=$1

for p in $(ls "$scriptdir"/../$repo/); do
    update $p
done
