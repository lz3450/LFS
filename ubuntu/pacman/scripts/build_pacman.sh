#!/bin/bash

set -e -u
# set -x

BUILDDIR=/tmp
pacmanver=$(curl -L -A 'Mozilla/5.0' --stderr - https://gitlab.archlinux.org/pacman/pacman/-/tags | grep -Po '(?<=/pacman/-/tags/v)\d\.\d\.\d' | head -1)

sudo apt update
sudo apt install -y \
    cmake meson ninja-build autoconf m4 pkg-config\
    curl libssl-dev libcurl4-openssl-dev libassuan-dev libarchive-tools libarchive-dev libgpgme-dev fakeroot fakechroot zstd \
    zlib1g-dev \
    valgrind \
    liblzma-dev \
    swig \
    libedit-dev \
    rsync \
    libelf-dev \
    libffi-dev \
    flex bison \
    python3-setuptools

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
    --sysconfdir etc \
    --optimization 2 \
    -D b_lto=true \
    -D b_pie=true \
    -D buildstatic=false \
    -D crypto=openssl \
    -D curl=enabled \
    -D doc=disabled \
    -D doxygen=disabled \
    -D file-seccomp=enabled \
    -D gpgme=enabled \
    -D ldconfig=/usr/bin/ldconfig \
    -D pkg-ext='.pkg.tar.zst' \
    -D scriptlet-shell=/usr/bin/bash \
    -D src-ext='.src.tar.zst' \
    -D use-git-version=true \
    build

# meson compile -C build
ninja -C build
meson test -C build || :
sudo meson install -C build

sudo sed -e '/^CHOST=/s/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/' \
    -e '/^#CPPFLAGS=/c\CPPFLAGS=""' \
    -e '/^#CFLAGS=/c\CFLAGS="-march=native -O2 -pipe -fno-plt -fexceptions -fstack-clash-protection -fcf-protection -Wp,-D_FORTIFY_SOURCE=2"' \
    -e '/^#CXXFLAGS=/c\CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"' \
    -e '/^#LDFLAGS=/c\LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"' \
    -e '/^#RUSTFLAGS=/c\RUSTFLAGS="-C opt-level=2"' \
    -e '/^#MAKEFLAGS=/c\MAKEFLAGS="-j$(nproc) -O"' \
    -e '/^#DEBUG_CFLAGS=/c\DEBUG_CFLAGS="-g -fvar-tracking-assignments"' \
    -e '/^#DEBUG_CXXFLAGS=/c\DEBUG_CXXFLAGS="-g -fvar-tracking-assignments"' \
    -e '/^#DEBUG_RUSTFLAGS=/c\DEBUG_RUSTFLAGS="-C debuginfo=2"' \
    -e '/^#BUILDDIR=/c\BUILDDIR="$HOME/makepkg/build"' \
    -e '/^INTEGRITY_CHECK=/s/(.*)/(sha256)/' \
    -e '/^#PKGDEST=/c\PKGDEST="$HOME/makepkg/packages"' \
    -e '/^#SRCDEST=/c\SRCDEST="$HOME/makepkg/sources"' \
    -e '/^#SRCPKGDEST=/c\SRCPKGDEST="$HOME/makepkg/srcpackages"' \
    -e '/^#LOGDEST=/c\LOGDEST="$HOME/makepkg/makepkglogs"' \
    -e '/^#PACKAGER=/c\PACKAGER="Zelun Kong <zelun.kong@outlook.com>"' \
    -e '/^OPTIONS=/s/libtool/!libtool/' \
    -i /usr/local/etc/makepkg.conf

sudo tee -a /usr/local/etc/pacman.conf << EOF

[kzl]
SigLevel = Optional TrustAll
Server = file:///home/.repository/\$repo
EOF
