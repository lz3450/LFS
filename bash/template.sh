#!/bin/bash
#
# template.sh
#

set -e
set -o pipefail
set -u
# set -x

umask 0022

# unset __DEBUG__
# __DEBUG__=1

SCRIPT_NAME="$(basename "$0")"
SCRIPT_PATH="$0"
# SCRIPT_PATH="$(realpath "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

################################################################################

### libraries
. "$SCRIPT_DIR"/lib/log.sh
. "$SCRIPT_DIR"/lib/utils.sh
# . "$SCRIPT_DIR"/lib/loop.sh
# . "$SCRIPT_DIR"/lib/chroot.sh

### checks
# if [[ $EUID -ne 0 ]]; then
#     error "This script must be run as root" 255
# fi
check_root

### constants & variables
VERSION="1.0"

declare -i verbose=0
input=

### functions
example_function() {
    info "example_function"

    sleep 1

    echo "$input"
}

clean() {
    info "clean"

    trap - EXIT SIGINT SIGTERM SIGKILL
}
trap clean EXIT SIGINT SIGTERM SIGKILL
# trap "trap - SIGTERM && kill -- -$$" EXIT SIGINT SIGTERM SIGKILL

usage() {
    cat << EOF

Usage: $SCRIPT_NAME -V | --version
Usage: $SCRIPT_NAME -h | --help
Usage: $SCRIPT_NAME [-v | --verbose ] -i | --input <arg>

    -V, --version                   print the script version number and exit
    -h, --help                      print this help message and exit
    -i, --input <arg>               argument
    -v, --verbose                   verbose

EOF
}

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
#         shift
#         if [[ -z "$1" || "$1" =~ ^- ]]; then
#             error "Missing value for input"
#         fi
#         input="$1"
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

while (( $# > 0 )); do
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
        error "Unknown option: $1" 127
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
# 127: Unknown option
# 255: Must be run as root
