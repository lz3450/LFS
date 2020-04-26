#!/bin/bash
# 
# update_repo.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

pkgs=(
    acl
    argon2
    attr
    audit
    autoconf
    automake
    base
    bash
    bc
    binutils
    bison
    boost
    bzip2
    ca-certificates
    cmake
    coreutils
    cracklib
    cryptsetup
    curl
    cython
    db
    dbus
    diffutils
    e2fsprogs
    ed
    elfutils
    expat
    fakeroot
    file
    findutils
    flex
    gawk
    gc
    gcc
    gdb
    gdbm
    gettext
    git
    glib2
    glibc
    gmp
    gnupg
    gnutls
    gnu-efi
    gperf
    gpgme
    grep
    guile
    gzip
    hidapi
    iana-etc
    icu
    iproute2
    iptables
    iputils
    itstool
    jsoncpp
    json-c
    kbd
    keyutils
    kmod
    krb5
    lapack
    less
    libaio
    libarchive
    libassuan
    libcap
    libcap-ng
    libcbor
    libedit
    libffi
    libfido2
    libgcrypt
    libgpg-error
    libidn2
    libksba
    libmicrohttpd
    libmnl
    libnetfilter_conntrack
    libnfnetlink
    libnftnl
    libnghttp2
    libnl
    libnsl
    libpcap
    libpng
    libpsl
    libsasl
    libseccomp
    libssh2
    libtasn1
    libtirpc
    libtool
    libunistring
    libusb
    libusb-compat
    libuv
    libxml2
    linux
    linux-api-headers
    lvm2 device-mapper
    lz4
    m4
    make
    meson
    mpc
    mpfr
    nano
    ncurses
    nettle
    ninja
    npth
    nss
    libldap # openldap
    openssh
    openssl
    p11-kit
    pacman
    pam
    patch
    pciutils
    pcre
    pcre2
    pcsclite
    perl
    pkgconf
    popt
    procps-ng
    psmisc
    publicsuffix-list
    python
    python-numpy
    qrencode
    readline
    rhash
    sed
    shadow
    shared-mime-info
    sqlite
    sudo
    swig
    systemd
    tar
    tcl
    thin-provisioning-tools
    tzdata
    util-linux
    valgrind
    which
    xz
    zlib minizip
    zstd
)

update() {
    sudo repo-add -R $LFS/pkgs/core.db.tar.gz $LFS/pkgs/$1-*.pkg.tar.gz
}

for r in $(find $LFS/pkgs -name "core.*"); do
    rm -f $r
done

for p in ${pkgs[@]}; do
    update $p
done
