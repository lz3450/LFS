#!/bin/bash
#
# template.sh
#

script_name="$(basename "$0")"
script_path="$(readlink -f "$0")"
script_dir="$(dirname "$script_path")"
version="1.0"
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
    if [[ "$_error" -gt 0 ]]; then
        exit "$_error"
    fi
}

usage() {
    local _usage="
    Usage: $script_name -V | --version
    Usage: $script_name -h | --help
    Usage: $script_name [-v | --verbose ] -i | --input <arg>

    -V, --version                   print the script version number and exit
    -h, --help                      print this help message and exit
    -i, --input <arg>               argument
    -v, --verbose                   verbose
"
    echo "$_usage"
}

example_function() {
    info "example_function"

    echo $input
}

cleanup() {
    info "cleanup"
}
trap cleanup EXIT SIGINT SIGTERM SIGKILL
# trap "trap - SIGTERM && kill -- -$$" EXIT SIGINT SIGTERM SIGKILL

################################################################################

set -e
# set -x

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
    -V | --version )
        echo "$version"
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

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "               Create Raspberry Pi image                "
echo -e "****************************************************************"
echo -e "[$script_name]: Start time - $(date)"
echo -e "\e[0m"

start_time=$(date +%s)

example_function
cleanup

end_time=$(date +%s)
total_time=$((end_time - start_time))

echo -e "\e[1;30m"
echo -e "****************************************************************"
echo -e "                Execution time Information                "
echo -e "****************************************************************"
echo -e "[$script_name]: End time - $(date)"
echo -e "[$script_name]: Total time - $(date -d@$total_time -u +%H:%M:%S)"
echo -e "\e[0m"
