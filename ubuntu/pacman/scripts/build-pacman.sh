#!/bin/bash

set -e
# set -x

SCRIPT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
BUILDDIR="/tmp"
PKGBUILDDIR="$SCRIPT_DIR/../pkgbuilds/ubuntu/pacman"

msg2() {
  echo "  --> $1"
}


sudo apt-get update
sudo apt-get upgrade -y
"$PKGBUILDDIR"/install-dependencies.sh

. "$PKGBUILDDIR"/PKGBUILD
export pkgname
export pkgdir="/tmp/pacman/install"

rm -rf "$BUILDDIR"/pacman
mkdir -p "$BUILDDIR"/pacman
cd "$BUILDDIR"
git clone https://gitlab.archlinux.org/pacman/pacman.git

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

echo "pacman has been installed successfully"
