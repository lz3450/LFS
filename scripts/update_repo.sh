#!/bin/bash
# 
# update_repo.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

base_pkgs=(
    autoconf
    automake
    base
    bash
    binutils
    bison
    bzip2
    cmake
    coreutils
    dbus
    e2fsprogs
    fakeroot
    file
    findutils
    flex
    gawk
    gcc
    gettext
    git
    glibc
    grep
    gzip
    iana-etc
    iproute2
    iputils
    libtool
    linux
    linux-api-headers
    m4
    make
    meson
    ncurses
    ninja
    pacman
    patch
    pciutils
    perl
    pkgconf
    procps-ng
    psmisc
    python
    readline
    sed
    shadow
    sudo
    systemd
    tar
    tzdata
    util-linux
    which
    xz
    zlib
)

core_pkgs=(
    acl
    argon2
    attr
    audit
    bc
    boost
    ca-certificates
    cracklib
    cryptsetup
    curl
    cython
    db
    diffutils
    ed
    elfutils
    expat
    gc
    gdb
    gdbm
    glib2
    gmp
    gnupg
    gnutls
    gnu-efi
    gperf
    gpgme
    guile
    hidapi
    icu
    iptables
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
    libunistring
    libusb
    libusb-compat
    libuv
    libxml2
    lvm2 device-mapper
    lz4
    mpc
    mpfr
    nettle
    npth
    nss
    libldap #openldap
    openssh
    openssl
    p11-kit
    pam
    pcre
    pcre2
    pcsclite
    popt
    publicsuffix-list
    python-numpy
    qrencode
    rhash
    shared-mime-info
    sqlite
    swig
    tcl
    thin-provisioning-tools
    valgrind
    zstd
)

update() {
    sudo repo-add -R $LFS/pkgs/$1.db.tar.gz $LFS/pkgs/$2-*.pkg.tar.gz
}

case $1 in
    base)
        pkgs=${base_pkgs[@]}
        repo='base'
        ;;
    core)
        pkgs=${core_pkgs[@]}
        repo='core'
        ;;
    *)
        # unknow repo
        exit 1
        ;;
esac

for r in $(find $LFS/pkgs -name "$repo.db*"); do
    rm -f $r
done

for p in ${pkgs[@]}; do
    update $repo $p
done
