#!/bin/bash

set -e
set -u
# set -x

BUILDDIR="/tmp"
PKGBUILDDIR="../pkgbuilds/kzl/pacman"
pkgdir=""

sudo apt-get update
sudo apt-get upgrade -y
"$PKGBUILDDIR"/install-dependencies.sh

. "$PKGBUILDDIR"/PKGBUILD

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
package=$(declare -f package)
sudo bash -xc "$package; package"