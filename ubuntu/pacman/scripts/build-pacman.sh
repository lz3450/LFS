#!/bin/bash

set -e
set -u
# set -x

export BUILDDIR="/tmp"
PKGBUILDDIR="../pkgbuilds/kzl/pacman"

# sudo apt-get update
# sudo apt-get upgrade -y
# "$PKGBUILDDIR"/install-dependencies.sh

. "$PKGBUILDDIR"/PKGBUILD
export pkgdir=""
export pkgname
export -f package

rm -rf "$BUILDDIR"/pacman
mkdir -p "$BUILDDIR"/pacman
cd "$BUILDDIR"
git clone https://gitlab.archlinux.org/pacman/pacman.git

pushd pacman
git checkout "${source#*\#commit=}"
popd

cd "$BUILDDIR"
build
# cd "$BUILDDIR"
# check || :
sudo bash -c "$(declare -f package); cd "$BUILDDIR/$pkgname"; pwd; package"
