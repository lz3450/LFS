#!/bin/bash

set -e
# set -x

if [ -n "$BASH_VERSION" ]; then
  export script_dir="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P)"
elif [ -n "$ZSH_VERSION" ]; then
  export script_dir="$(cd -- "$(dirname "${(%):-%x}")" >/dev/null 2>&1; pwd -P)"
else
  echo "Unsupported shell"
fi

export BUILDDIR="/tmp"
export PKGBUILDDIR="$script_dir/../pkgbuilds/kzl/pacman"
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

if [ -n "$_ref" ]; then
  pushd pacman
  git checkout "$_ref"
  popd
fi

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

sudo ldconfig

echo "pacman has been installed successfully"
