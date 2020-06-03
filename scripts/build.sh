#!/bin/bash
# 
# build.sh
#

set -xu -o pipefail

scriptdir=$(pwd)

failed_pkgs=()

build() {
    local pkg
    pkg=$1

    cd $pkg

    local log
    log=build.log
    if [[ -f $log ]]; then
        rm $log
    fi

    makepkg -scCf --nocheck --noconfirm &>> $log

    if [ $? -ne 0 ]; then
        failed_pkgs+=($pkg)
    fi
}

case $1 in
    linux)
        pkgs="$scriptdir"/../linux
        ;;
    core|extra)
        pkgs=$(ls -d $scriptdir/../$1/[a-z]*)
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

for p in ${pkgs[@]}; do
    build $p
done

if [ ${#failed_pkgs[@]} -eq 0 ]; then
    echo "Build all packages successfully. "
else
    echo ${failed_pkgs[@]}
    exit -1
fi
