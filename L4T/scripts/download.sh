#!/bin/bash
#
# download.sh
#

# https://developer.nvidia.com/embedded/linux-tegra

BSP_NAME="jetson-210_linux_r32.5.1_aarch64.tbz2"
QWMU_NAME="qemu-user-static_5.2+dfsg-10_amd64.deb"
GRML_NAME="grml-etc-core_0.18.0_all.deb"
ZSH_AUTOSUGGESTIONS="zsh-autosuggestions_0.6.4-1_all.deb"

download() {
    local name=$1
    local link=$2

    if [ ! -f ${ROOTDIR}/downloads/$name ]; then
        wget $link/$name -P ${ROOTDIR}/downloads/
    fi
}

################################################################################

mkdir -p ${ROOTDIR}/downloads

# L4T BSP
# https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/rootfs_custom.html#
download $BSP_NAME "https://developer.nvidia.com/embedded/l4t/r32_release_v5.1/r32_release_v5.1/t210"

# qemu-user-static
download $QWMU_NAME "https://deb.debian.org/debian/pool/main/q/qemu"

tmpdir="$(mktemp -d)"
dpkg -x ${ROOTDIR}/downloads/$QWMU_NAME "${tmpdir}"
sudo cp "${tmpdir}"/usr/bin/qemu-aarch64-static /usr/bin/qemu-aarch64-static
rm -rf "${tmpdir}"

echo ":qemu-aarch64:M::\x7fELF\x02\x01\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\xb7:\xff\xff\xff\xff\xff\xff\xff\x00\xff\xff\xff\xff\xff\xff\xff\xff\xfe\xff\xff:/usr/bin/qemu-aarch64-static:CF" \
    | sudo tee /usr/lib/binfmt.d/qemu-user-static.conf

download $GRML_NAME "http://deb.grml.org/pool/main/g/grml-etc-core"
download $ZSH_AUTOSUGGESTIONS "http://deb.debian.org/debian/pool/main/z/zsh-autosuggestions"

mv ${ROOTDIR}/downloads/$GRML_NAME mksamplefs/
mv ${ROOTDIR}/downloads/$ZSH_AUTOSUGGESTIONS mksamplefs/