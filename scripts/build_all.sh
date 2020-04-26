#!/bin/bash
# 
# build_all.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

scriptdir=$(pwd)
logdir="$scriptdir"/../log

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
    zlib minizip
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
    lvm2
    lz4
    mpc
    mpfr
    nettle
    npth
    nss
    openldap
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

build() {
    log="$logdir"/$2.log
    if [[ -f $log ]]; then
        rm $log
    fi
    cd "$scriptdir"/../$1/$2
    # gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
    makepkg --config "$scriptdir"/../config/makepkg-lfs.conf -scCLf &>> $log
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

if [[ ! -d $logdir ]]; then
    mkdir -p $logdir
fi

for p in ${pkgs[@]}
do
    build $repo $p
    # sudo repo-add $LFS/pkgs/$repo.db.tar.gz $LFS/pkgs/$p-*.pkg.tar.gz &>> $log
done