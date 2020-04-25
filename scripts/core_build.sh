#!/bin/bash
# 
# core_build.sh
#

set -exu -o pipefail

LFS=/mnt/lfs

scriptdir=$(pwd)
logdir="$scriptdir"/../log
pkgs=(
    acl
    argon2
    attr
    audit
    boost
    ca-certificates
    cracklib
    cryptsetup
    curl
    cython
    db
    # device-mapper: lvm2
    diffutils
    ed
    elfutils
    expat
    gdb
    gdbm
    glib2
    gmp
    gnu-efi
    gnutls
    gnupg
    gperf
    gpgme
    guile
    hidapi
    icu
    iptables
    itstool
    json-c
    jsoncpp
    kbd
    keyutils
    kmod
    krb5
    lapack
    less
    libaio
    libarchive
    libcap
    libcap-ng
    libedit
    libffi
    libfido2
    libgcrypt
    libgpg-error
    libidn2
    libldap
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
    libtirpc
    libunistring
    libusb
    libusb-compat
    libuv
    libxml2
    linux-headers
    lvm2
    lz4
    mpc
    mpfr
    openssh
    openssl
    p11-kit
    pam
    pcre
    pcre2
    popt
    publicsuffix-list
    python-numpy
    qrencode
    rhash
    shared-mime-info
    sqlite
    swig
    thin-provisioning-tools
    tcl
    valgrind
    zstd
)

if [[ ! -d $logdir ]]; then
    mkdir -p $logdir
fi

for p in ${pkgs[@]}
do
    echo $p
    log="$logdir"/$p.log
    if [[ -f $log ]]; then
        rm $log
    fi
    cd "$scriptdir"/../core/$p
    # gpg --recv-keys $(grep -E -o "[0-9A-F]{40}" PKGBUILD)
    updpkgsums
    makepkg --config "$scriptdir"/../config/makepkg-lfs.conf -dcCLf &>> $log
    sudo repo-add $LFS/pkgs/core.db.tar.gz $LFS/pkgs/$p-*.pkg.tar.gz &>> $log
done

sudo repo-add $LFS/pkgs/core.db.tar.gz $LFS/pkgs/device-mapper-*.pkg.tar.gz