#!/usr/bin/bash
#
# template.sh
#

set -e
set -u
set -o pipefail
# set -x

umask 0022

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
BASH_LIB_DIR=${BASH_LIB_DIR:-"/home/kzl/LFS/bash/lib"}

################################################################################

### libraries
source "$BASH_LIB_DIR/log.sh"

### checks
if [[ $EUID -ne 0 ]]; then
    error "This script must be run as root" 1
fi

### constants & variables
VERSION="1.0"

verbose=false
input=

### functions
usage() {
    cat <<EOF
Usage: $script_name -V | --version
Usage: $script_name -h | --help
Usage: $script_name [-v | --verbose ] -i | --input <arg>

-V, --version                   print the script version number and exit
-h, --help                      print this help message and exit
-i, --input <arg>               argument
-v, --verbose                   verbose

EOF
}

example_function() {
    info "example_function"

    sleep 1

    echo $input
}

clean() {
    info "clean"

    trap - EXIT SIGINT SIGTERM SIGKILL
}
trap clean EXIT SIGINT SIGTERM SIGKILL
# trap "trap - SIGTERM && kill -- -$$" EXIT SIGINT SIGTERM SIGKILL

################################################################################

# while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do
#     case "$1" in
#     -V | --version )
#         echo "$version"
#         exit
#         ;;
#     -h | --help)
#         usage
#         ;;
#     -i | --input)
#         shift; input="$1"
#         ;;
#     -v | --verbose)
#         shift; verbose=true
#         ;;
#     *)
#         usage
#         error "Unknown option: $1"
#         ;;
#     esac
#     shift
# done
# if [[ "$1" == '--' ]]; then shift; fi

while (($# > 0)); do
    case "$1" in
    -V | --version)
        echo "$VERSION"
        exit
        ;;
    -h | --help)
        usage
        ;;
    -i | --input)
        shift; input="$1"
        ;;
    -v | --verbose)
        shift; verbose=true
        ;;
    *)
        usage
        error "Unknown option: $1"
        ;;
    esac
    shift
done

################################################################################

prologue

example_function
clean

epilogue

### error codes
# 1: must be run as root
