#!/usr/bin/bash
#
# lib/log.sh
#

set -e
set -u
set -o pipefail
# set -x

################################################################################

### functions
# Show an INFO message
# $1: message string
info() {
    local _msg="$1"
    printf '\033[0;32m[%s] INFO: %s\033[0m\n' "$SCRIPT_NAME" "$_msg"
}

# Show a WARNING message
# $1: message string
warning() {
    local _msg="$1"
    printf '\033[0;33m[%s] WARNING: %s\033[0m\n' "$SCRIPT_NAME" "$_msg" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local _msg="$1"
    local _error="$2"
    printf '\033[0;31m[%s] ERROR: %s\033[0m\n' "$SCRIPT_NAME" "$_msg" >&2
    if [[ "$_error" -gt 0 ]]; then
        exit "$_error"
    fi
}

prologue() {
    echo -e "\e[1;30m"
    echo -e "****************************************************************"
    echo -e "* $SCRIPT_NAME"
    echo -e "****************************************************************"
    echo -e "[$SCRIPT_NAME]: Start time - $(date)"
    echo -e "\e[0m"

    __start_time__=$(date +%s)
}

epilogue() {
    __end_time__=$(date +%s)
    __total_time__=$(($__end_time__ - $__start_time__))

    echo -e "\e[1;30m"
    echo -e "****************************************************************"
    echo -e "* Execution time Information"
    echo -e "****************************************************************"
    echo -e "[$SCRIPT_NAME]: End time - $(date)"
    echo -e "[$SCRIPT_NAME]: Total time - $(date -d@$__total_time__ -u +%H:%M:%S)"
    echo -e "\e[0m"
}