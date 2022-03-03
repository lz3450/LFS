#!/bin/bash
#
# template.sh
#

set -e
# set -x

script_name="$(basename "${0}")"
script_path="$(readlink -f "${0}")"
script_dir="$(dirname "${script_path}")"

input=

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
    echo "example_function"

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
