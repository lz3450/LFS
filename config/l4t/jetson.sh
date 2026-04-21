#!/bin/bash
#
# jetson.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
bsp_number=""
bsp_name=""
bsp_version="32.7.1"
l4t_dir="${ROOTDIR}/${bsp_name}/Linux_for_Tegra"
chroot_path="/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"

usage() {
    errno=0
    if [ -n "${1}" ]; then
        echo "${1}"
        errno=1
    fi

    echo "Usage: ${script_name} [ -h | --help ] -b|--bsp <bsp_name> [ -c | --clean ] [ -V | --verbose ]"
    echo
    echo "    -h, --help        display this help message and exit"
    echo "    -b, --bsp         specify the bsp name (t186, t210)"
    echo "    -c, --clean       clean workspace"
    echo "    -V, --verbose     display more info"
    echo
    exit ${errno}
}

download() {
    local bsp="${bsp_name}_linux_r${bsp_version}_aarch64.tbz2"
    local version

    if [ ! -f ${ROOTDIR}/downloads/${bsp} ]; then
        wget -P ${ROOTDIR}/downloads/ -c "https://developer.nvidia.com/embedded/l4t/r${bsp_version%%.*}_release_v${bsp_version#*.}/${bsp_number}/${bsp}"
        wget -O ${ROOTDIR}/downloads/${bsp_name}_public_sources.tbz2 -c "https://developer.nvidia.com/embedded/l4t/r${bsp_version%%.*}_release_v${bsp_version#*.}/sources/${bsp_number}/public_sources.tbz2"
    fi
}

toolchain() {
    local name="l4t-gcc-7-3-1-toolchain-64-bit"

    if [ ! -f ${ROOTDIR}/downloads/${name}.tbz2 ]; then
        wget -O ${ROOTDIR}/downloads/${name}.tbz2 -c "https://developer.nvidia.com/embedded/dlc/${name}"
    fi
}

init_l4t() {
    if [ ! -d "${ROOTDIR}/${bsp_name}" ]; then
        mkdir -p "${ROOTDIR}"/${bsp_name}
        tar -xf "${ROOTDIR}"/downloads/${bsp_name}_linux_r${bsp_version}_aarch64.tbz2 -C "${ROOTDIR}"/${bsp_name}
        tar -xf "${ROOTDIR}"/downloads/${bsp_name}_public_sources.tbz2 -C "${ROOTDIR}"/${bsp_name}
    fi

    pushd "${l4t_dir}" > /dev/null 2>&1

    sudo rm -rf rootfs/*

    pushd rootfs > /dev/null 2>&1
    sudo tar -xpf "${ROOTDIR}"/mksamplefs/sample_fs.tbz2
    popd > /dev/null

    sudo PATH="${chroot_path}" ./apply_binaries.sh

    popd > /dev/null

    if [ ${bsp_number} == "t186" ]; then
        sed 's|/usr/bin/w:|/usr/bin/w.procps:|' -i "${ROOTDIR}"/${bsp_name}/Linux_for_Tegra/tools/ota_tools/version_upgrade/recovery_copy_binlist.txt
        echo '428a414a-de2b-4220-927d-f4bc3280592a' | sudo tee "${ROOTDIR}"/${bsp_name}/Linux_for_Tegra/bootloader/l4t-rootfs-uuid.txt_ext
        sed 's|isolcpus=1-2|isolcpus=|' -i "${ROOTDIR}"/jetson/Linux_for_Tegra/p2771-0000.conf.common
    elif [ ${bsp_number} == "t210" ]; then
        pushd "${l4t_dir}"/tools > /dev/null 2>&1
        sudo ./jetson-disk-image-creator.sh -o "${l4t_dir}"/sd_blob.img -b jetson-nano-2gb-devkit
        popd > /dev/null
    fi
}

################################################################################

while [ -n "${1}" ]; do
    case "${1}" in
    -h|--help)
        usage
        ;;
    -b|--bsp)
        bsp_number="${2}"
        shift 2
        ;;
    -c|--clean)
        sudo rm -rf "${ROOTDIR}"/{jetson,jetson-210}
        exit 0
        ;;
    -V|--verbose)
        verbose=true
        shift 1
        ;;
    *)
        usage "Unknown option: ${1}"
        ;;
    esac
done

if [ -z "${bsp_number}" ] || ([ $bsp_number != "t186" ] && [ ${bsp_number} != "t210" ]); then
    usage "Incurrect or no <bsp_name> provided."
fi

start_time=$(date +%s)

echo "********************************************************************************"
echo "    Initialize Linux for Tegra"
echo "********************************************************************************"

mkdir -p ${ROOTDIR}/downloads

# L4T BSP
# https://docs.nvidia.com/jetson/l4t/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/rootfs_custom.html#

if [ ${bsp_number} == "t186" ]; then
    bsp_name="jetson"
elif [ ${bsp_number} == "t210" ]; then
    bsp_name="jetson-210"
fi

download
toolchain

l4t_dir="${ROOTDIR}/${bsp_name}/Linux_for_Tegra"

init_l4t

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "********************************************************************************"
echo "    Execution time Information"
echo "********************************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"