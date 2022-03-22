#!/bin/bash

set -e

BUILDDIR=/dev/shm
pacmanver=6.0.1

cd $BUILDDIR
if [ ! -f pacman-$pacmanver.tar.gz ]; then
    wget https://sources.archlinux.org/other/pacman/pacman-$pacmanver.tar.xz
fi

if [ -d pacman-$pacmanver ]; then
    rm -rf pacman-$pacmanver
fi

tar -xf pacman-$pacmanver.tar.xz
cd pacman-$pacmanver

meson setup \
  --prefix /usr/local \
  --libexecdir lib \
  --sbindir bin \
  --sysconfdir etc \
  --auto-features enabled \
  --buildtype plain \
  --wrap-mode nodownload \
  -D b_lto=true \
  -D b_pie=true \
  -D buildstatic=false \
  -D doc=disabled \
  -D doxygen=disabled \
  -D ldconfig=/usr/bin/ldconfig \
  -D pkg-ext='.pkg.tar.zst' \
  -D scriptlet-shell=/usr/bin/bash \
  -D src-ext='.src.tar.zst' \
  build

meson compile -C build
meson test -C build || :
sudo meson install -C build

sudo sed -e '/^CHOST=/s/x86_64-pc-linux-gnu/x86_64-kzl-linux-gnu/' \
    -e '/^#CFLAGS=/c\CFLAGS="-march=native -O2 -pipe -fno-plt -fexceptions -fstack-clash-protection -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"' \
    -e '/^#CXXFLAGS=/c\CXXFLAGS="-march=native -O2 -pipe -fno-plt -fexceptions -fstack-clash-protection -fcf-protection -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS"' \
    -e '/^#LDFLAGS=/c\LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"' \
    -e '/^#RUSTFLAGS=/c\RUSTFLAGS="-C opt-level=2"' \
    -e '/^#MAKEFLAGS=/c\MAKEFLAGS="-j$(nproc)"' \
    -e '/^#DEBUG_CFLAGS=/c\DEBUG_CFLAGS="-g -fvar-tracking-assignments"' \
    -e '/^#DEBUG_CXXFLAGS=/c\DEBUG_CXXFLAGS="-g -fvar-tracking-assignments"' \
    -e '/^#DEBUG_RUSTFLAGS=/c\DEBUG_RUSTFLAGS="-C debuginfo=2"' \
    -e '/^#BUILDDIR=/c\BUILDDIR=/dev/shm/makepkg' \
    -e '/^INTEGRITY_CHECK=/s/(.*)/(sha256)/' \
    -e '/^#PKGDEST=/c\PKGDEST="$HOME/makepkg/packages"' \
    -e '/^#SRCDEST=/c\SRCDEST="$HOME/makepkg/sources"' \
    -e '/^#SRCPKGDEST=/c\SRCPKGDEST="$HOME/makepkg/srcpackages"' \
    -e '/^#LOGDEST=/c\LOGDEST="$HOME/makepkg/makepkglogs"' \
    -e '/^#PACKAGER=/c\PACKAGER="Zelun Kong <zelun.kong@outlook.com>"' \
    -i /usr/local/etc/makepkg.conf

sudo tee -a /usr/local/etc/pacman.conf << EOF

[kzl]
SigLevel = Optional TrustAll
Server = file:///home/.repository/\$repo
EOF

sudo ldconfig
