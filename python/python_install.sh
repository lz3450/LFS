#!/bin/bash
#
# python_install.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"

pkgs=()
uptodate_pkgs=()

WHEEL_DIR="$HOME/python/wheels"
SOURCE_DIR="$HOME/python/sources"

# Show an INFO message
# $1: message string
info() {
    local _msg="${1}"
    printf '[%s] INFO: %s\n' "${script_name}" "${_msg}"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="${1}"
    printf '[%s] WARNING: %s\n' "${script_name}" "${_msg}" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="${1}"
    local _error=${2}
    printf '[%s] ERROR: %s\n' "${script_name}" "${_msg}" >&2
    if (( _error > 0 )); then
        exit "${_error}"
    fi
}

# Show help usage.
usage() {
    printf "%s" "\
Usage: ${script_name} [ -h | --help ] [ -V | --verbose ] <pkgs>
    -h      display this help message
    -v      display version

    pkgs    packages to be installed"
}

# List installed uptodate packages.
get_uptodate_pkgs() {
    IFS=$'\n'
    uptodate_pkgs=($(sed "s/==.*$//g" <<< $(python3 -m pip list -u --format=freeze)))
    unset IFS
}

# List dependencies of package.
# $1: package name.
_list_dep() {
    local _pkg=${1}

    python3 -m pip show ${_pkg} | grep -i "^requires" | sed -e "s/^Requires: //;s/, / /g"
}

# Build and install a single python package.
# $1: package name.
_install_pkg() {
    local _pkg=${1}
    local _name_regex="$(sed "s/-/_/g" <<< $_pkg)-\([0-9a-zA-Z]+\.?\)+-.+\.whl"

    IFS=$'\n'
    local _find_result=($(find $WHEEL_DIR -type f -iregex "$WHEEL_DIR/$_name_regex" -printf "%f\n"))
    # if wheel file already exists
    if (( ${#_find_result[*]} )); then
        # if wheel file is up-to-date
        if [[ "${IFS}${uptodate_pkgs[*],,}${IFS}" =~ "${IFS}${_pkg,,}${IFS}" ]]; then
            info "Package \"$_pkg\" is uptodate, skip."
            return
        else
            for _f in ${_find_result[*]}; do
                info "Wheel \"$_f\" is outdated, remove."
                rm -f "$WHEEL_DIR/$_f"
            done
        fi
    fi
    unset IFS

    info "Download package \"${_pkg}\" ..."
    python3 -m pip download --no-binary :all: --no-deps -d $SOURCE_DIR -v ${_pkg}

    info "Building package \"${_pkg}\" ..."
    python3 -m pip wheel -w $WHEEL_DIR --no-binary ${_pkg} --no-deps --no-index --find-links $WHEEL_DIR --find-links $SOURCE_DIR --verbose ${_pkg}

    info "Installing package \"${_pkg}\" ..."
    sudo python3 -m pip install -U --no-deps --no-index --find-links $WHEEL_DIR --verbose ${_pkg}

}

# Build and install a python package and its dependencies.
# $1: package name.
python_install() {
    local _pkg=${1}

    IFS=' '
    local _deps=($(_list_dep ${_pkg}))

    info "Dependencies of package \"${_pkg}\":"
    printf "\t%s\n" ${_deps[@]}

    if (( ${#_deps[@]} )); then
        for _d in ${_deps[@]}; do
            python_install ${_d}
        done
    fi
    unset IFS

    _install_pkg ${_pkg}
}

# $PIP list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 $PIP $WHEEL_ARGS
# $PIP list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1 | xargs -n1 $PIP $INSTALL_ARGS

################################################################

while getopts "lvh" arg; do
    case "${arg}" in
        h)
            usage
            exit 0
            ;;
        v)
            ;;
        *)
            error "Invalid argument '${arg}'" 0
            ;;
    esac
done
shift $((OPTIND - 1))

if (( $# < 1 )); then
    error "No package name specified" 0
    usage
    exit 2
fi

start_time=$(date +%s)

printf "%s" "\
****************************************************************
                python_install.sh
****************************************************************
"

get_uptodate_pkgs
while [ -n "${1}" ]; do
    python_install ${1}
    shift
done

end_time=$(date +%s)
total_time=$((end_time-start_time))

printf "%s" "\
****************************************************************
                Execution time Information
****************************************************************
${script_name} : End time - $(date)
${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)
"
