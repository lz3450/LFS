#!/bin/bash
#
# template.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"
verbose=false
input=

# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '\033[0;32m[%s] INFO: %s\033[0m\n' "$script_name" "$_msg"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '\033[0;33m[%s] WARNING: %s\033[0m\n' "$script_name" "$_msg" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '\033[0;31m[%s] ERROR: %s\033[0m\n' "$script_name" "$_msg" >&2
    if [ "$_error" -gt 0 ]; then
        exit "$_error"
    fi
}

usage() {
    errno=0
    if [ -n "${1}" ]; then
        echo "${1}"
        errno=1
    fi

    echo "Usage: ${script_name} [ -h | --help ] -i | --input <input> [ -V | --verbose ]"
    echo
    echo "    -h, --help        display this help message and exit"
    echo "    -i, --input       option taking input example"
    echo "    -V, --verbose     display more info"
    echo
    exit ${errno}
}

example_function() {
    info "example_function"

    echo ${input}
}

cleanup() {
    echo "cleanup"
}
trap cleanup EXIT

################################################################

while [ -n "${1}" ]; do
    case "${1}" in
    -h|--help)
        usage
        ;;
    -i|--input)
        input="${2}"
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

start_time=$(date +%s)

echo "****************************************************************"
echo "                bash script template                "
echo "****************************************************************"

example_function
cleanup

end_time=$(date +%s)
total_time=$((end_time-start_time))

echo "****************************************************************"
echo "                Execution time Information                "
echo "****************************************************************"
echo "${script_name} : End time - $(date)"
echo "${script_name} : Total time - $(date -d@${total_time} -u +%H:%M:%S)"
