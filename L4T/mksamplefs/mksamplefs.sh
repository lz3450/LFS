#!/bin/bash
#
# mkimg_tegra.sh
#

set -e
# set -x

version=""
verbose=false
source_samplefs=""
script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
base_url="http://cdimage.ubuntu.com/ubuntu-base/releases/18.04/release/ubuntu-base-18.04.5-base-arm64.tar.gz"
base_tarball="${script_dir}/base.tar.gz"
output_samplefs="${script_dir}/sample_fs.tbz2"
tmpdir=""
img_file="/tmp/tegra.img"
package_list_file="${script_dir}/package_list.txt"
initialize_script_file="${script_dir}/initialize.sh"
chroot_path="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"

usage() {
    if [ -n "${1}" ]; then
        echo "${1}"
    fi

    echo "Usage: ${script_name} [-h | --help ] [-V | --verbose]"
    echo
    echo "    -h, --help        display this help message and exit"
    echo "    -b, --base        specify the base tarball [base.tar.gz]"
    echo "    -V, --verbose     display more info"
    echo
    exit 1
}

download_samplefs() {
    echo "download_samplefs"

    validate_url="$(wget -S --spider "${base_url}" 2>&1 | grep "HTTP/1.1 200 OK" || ret=$?)"
    if [ -z "${validate_url}" ]; then
        echo "ERROR: Cannot download base image, please check internet connection or the URL" > /dev/stderr
        exit 1
    fi

    if [ ! -f ${base_tarball} ]; then
        wget -O "${base_tarball}" "${base_url}" > /dev/null 2>&1
    fi
    source_samplefs="${base_tarball}"
}

extract_samplefs() {
    echo "extract_samplefs"
    tmpdir="$(mktemp -d)"
    chmod 755 "${tmpdir}"
    pushd "${tmpdir}" > /dev/null 2>&1
    tar -xpf "${source_samplefs}" --numeric-owner
    popd > /dev/null
}

debootstrap_samplefs() {
    echo "debootstrap_samplefs"
    tmpdir="$(mktemp -d)"
    chmod 755 "${tmpdir}"

    if [ -f ${img_file} ]; then
        rm ${img_file}
    fi

    # fallocate -l 6G ${img_file}
    # losetup -D
    # loop=$(losetup -f)
    # echo "Loop device is \"${loop}\""
    # losetup -P ${loop} ${img_file}
    # mkfs.ext4 ${loop}
    # mount ${loop} "${tmpdir}"

    pushd "${tmpdir}" > /dev/null 2>&1
    # --include="${package_list}" --no-merged-usr
    debootstrap --arch=arm64 --no-merged-usr bionic . http://ports.ubuntu.com/ubuntu-ports/
    cp -f "${script_dir}"/sources.list etc/apt
    popd > /dev/null
}

install_package() {
    local retry=0
    local retry_max=5

    echo "Install package \"${1}\""
    while true
    do
        local ret=0
        # LC_ALL=C PATH="${chroot_path}" chroot . apt -y install "${1}" || ret=$?
        LC_ALL=C PATH="${chroot_path}" chroot . apt -y --no-install-recommends install "${1}" || ret=$?
        if [ "${ret}" == "0" ]; then
            return 0
        else
            retry=$( expr $retry + 1 )
            if [ "${retry}" == "${retry_max}" ]; then
                return 1
            else
                sleep 1
                echo "Retrying ${1} package install"
            fi
        fi
    done
}

create_samplefs() {
    echo "create_samplefs"

    local host_qemu_path="/usr/bin/qemu-aarch64-static"
    local target_qemu_path="usr/bin/qemu-aarch64-static"

    if [ ! -e "${tmpdir}" ]; then
        echo "ERROR: Temporary directory not found" > /dev/srderr
        exit 1
    fi

    pushd "${tmpdir}" > /dev/null 2>&1
    if [ ! -f "${host_qemu_path}" ]; then
        echo "ERROR: ${host_qemu_path} not found" > /dev/srderr
        exit 1
    fi
	# cp "${host_qemu_path}" "${target_qemu_path}"
    # chmod 755 "${target_qemu_path}"

    # mount --rbind /sys ./sys
    # mount --rbind /proc ./proc
    # mount --rbind /dev ./dev
    # mount --rbind /run ./run

    for fs in dev sys proc run; do
        mount --rbind /$fs ./$fs
        mount --make-rslave ./$fs
    done

    mv etc/resolv.conf etc/resolv.conf.saved
    if [ -e "/run/resolvconf/resolv.conf" ]; then
        cp /run/resolvconf/resolv.conf etc/
    elif [ -e "/etc/resolv.conf" ]; then
        cp /etc/resolv.conf etc/
    fi

    local ret=0
    LC_ALL=C PATH="${chroot_path}" chroot . apt update || ret=$?
    LC_ALL=C PATH="${chroot_path}" chroot . apt upgrade -y || ret=$?
    LC_ALL=C PATH="${chroot_path}" chroot . apt dist-upgrade -y || ret=$?

    if [ "${ret}" == "0" ]; then
        package_list=$(cat "${package_list_file}")

        if [ ! -z "${package_list}" ]; then
            for package in ${package_list}
            do
                if ! install_package "${package}"; then
                    package_name="$(echo "${package}" | cut -d'=' -f1)"
                    if [ "${package_name}" = "${package}" ]; then
                        echo "ERROR: Failed to install ${package}"
                    else
                        echo "Try to install ${package_name} the latest version"
                        if ! install_package "${package_name}"; then
                            echo "ERROR: Failed to install ${package_name}"
                        fi
                    fi
                fi
            done
        fi
    fi

    # copy initialize script
    cp ${initialize_script_file} ./root/initialize.sh
    chmod +x ./root/initialize.sh

    LC_ALL=C PATH="${chroot_path}" chroot . /bin/bash -c "/root/initialize.sh"
    LC_ALL=C PATH="${chroot_path}" chroot . sync
    LC_ALL=C PATH="${chroot_path}" chroot . apt clean
    LC_ALL=C PATH="${chroot_path}" chroot . sync

    mv etc/resolv.conf.saved etc/resolv.conf

    # umount -R ./sys
    # umount -R ./proc
    # umount -R ./dev
    # umount -R ./run

    for fs in dev sys proc run; do
        umount -R ./$fs
    done

    # rm "${target_qemu_path}"

    rm -rf var/lib/apt/lists/*
    rm -rf dev/*
    rm -rf var/log/*
    rm -rf var/cache/apt/archives/*.deb
    rm -rf var/tmp/*
    rm -rf tmp/*

    popd > /dev/null
}

save_samplefs() {
    echo "save_samplefs"

    if [ -f "${output_samplefs}" ]; then
        rm -f "${output_samplefs}"
    fi

    pushd "${tmpdir}" > /dev/null 2>&1
    tar --numeric-owner -jcpf "${output_samplefs}" *
    sync
    popd > /dev/null
}

cleanup() {
    echo "cleanup"
    set +e

    if [ -n "${tmpdir}" ]; then
        for attempt in $(seq 10); do
            # mount | grep -q "${tmpdir}/sys" && umount -R ./sys
            # mount | grep -q "${tmpdir}/proc" && umount -R ./proc
            # mount | grep -q "${tmpdir}/dev/pts" && umount -R ./dev
            # mount | grep -q "${tmpdir}/dev" && umount -R ./dev
            for fs in dev/pts dev sys proc run; do
                mount | grep -q "${tmpdir}/$fs" && umount -R ./$fs
            done
            mount | grep -q "${tmpdir}" && umount "${tmpdir}"
            if [ $? -ne 0 ]; then
                break
            fi
            sleep 1
        done

        losetup -D
        rm -rf "${tmpdir}"
    fi
}
trap cleanup EXIT

################################################################################

while [ -n "${1}" ]; do
    case "${1}" in
    -h|--help)
        usage
        ;;
    -b|--base)
        base_tarball="${script_dir}/${2}"
        shift 2
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

# if [ -z "${abi}" ] || [ -z "${distro}" ] || [ -z "${version}" ]; then
#     usage
# fi

if [ "${verbose}" == true ]; then
	start_time=$(date +%s)
fi

echo "********************************************"
echo "     Create ${distro} sample filesystem     "
echo "********************************************"

if [ ! -f "${source_samplefs}" ]; then
    download_samplefs
fi
# extract_samplefs
debootstrap_samplefs

create_samplefs
save_samplefs

if [ "${verbose}" = true ]; then
    end_time=$(date +%s)
    total_time=$((end_time-start_time))

    echo "********************************************"
    echo "       Execution time Information           "
    echo "********************************************"
    echo "${script_name} : End time - $(date)"
    echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
fi

echo "********************************************"
echo "   ${distro} samplefs Creation Complete     "
echo "********************************************"
echo "Samplefs - ${output_samplefs} was generated."
