#!/bin/bash

set -e
set -u
# set -x

export BUILDDIR="/tmp"
export PKGBUILDDIR="../pkgbuilds/kzl/pacman"
export pkgdir="/tmp/pacman/install"

sudo apt-get update
sudo apt-get upgrade -y
"$PKGBUILDDIR"/install-dependencies.sh

. "$PKGBUILDDIR"/PKGBUILD
export pkgname

rm -rf "$BUILDDIR"/pacman
mkdir -p "$BUILDDIR"/pacman
cd "$BUILDDIR"
git clone https://gitlab.archlinux.org/pacman/pacman.git

pushd pacman
git checkout "${source#*\#commit=}"
popd

cd "$BUILDDIR"
prepare
cd "$BUILDDIR"
build
cd "$BUILDDIR"
check || :
cd "$BUILDDIR"
package
# sudo -E bash -xc "$(declare -f package); package"
sudo cp -ru "$pkgdir"/* /
