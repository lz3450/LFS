#!/bin/bash
#
# log.sh
#

################################################################################

if [[ -v __LIBLOG__ ]]; then
    return
fi

declare -r __LIBLOG__="log.sh"

################################################################################

### checks
if [[ -z "$SCRIPT_NAME" ]]; then
    echo "SCRIPT_NAME is not set. Please set it before sourcing this script" >&2
fi

### constants and variables
declare -i __start_time__
declare -i __end_time__
declare -i __total_time__

### functions
# Show a DEBUG message
# $1: message string
debug() {
    if [[ -z "${__DEBUG__:-}" ]]; then
        return
    fi
    printf '\033[0;34m[%s] DEBUG: %s\033[0m\n' "${2:-"$SCRIPT_NAME"}" "$1" >&2
}

# Show an INFO message
# $1: message string
info() {
    printf '\033[0;32m[%s] INFO: %s\033[0m\n' "${2:-"$SCRIPT_NAME"}" "$1" >&2
}

# Show a WARNING message
# $1: message string
warn() {
    printf '\033[0;33m[%s] WARNING: %s\033[0m\n' "${2:-"$SCRIPT_NAME"}" "$1" >&2
}

# Show an ERROR message then exit with status
# $1: message string
# $2: exit code number (with 0 does not exit)
error() {
    local -i _error="${2:-0}"
    printf '\033[0;31m[%s] ERROR: %s\033[0m\n' "${3:-"$SCRIPT_NAME"}" "$1" >&2
    if (( _error > 0 )); then
        exit "$_error"
    fi
}

log_red() {
    printf "\033[1;31m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}
log_green() {
    printf "\033[1;32m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}
log_yellow() {
    printf "\033[1;33m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}
log_blue() {
    printf "\033[1;34m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}
log_magenta() {
    local _src=${1:-"$SCRIPT_NAME"}
    printf "\033[1;35m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}
log_cyan() {
    local _src=${1:-"$SCRIPT_NAME"}
    printf "\033[1;36m[%s] %s\033[0m\n" "${2:-"$SCRIPT_NAME"}" "$1" >&2
}

prologue() {
    echo -e "\033[1;30m" >&2
    echo -e "****************************************************************" >&2
    echo -e "* $SCRIPT_NAME" >&2
    echo -e "****************************************************************" >&2
    echo -e "[$SCRIPT_NAME]: Start time - $(date)" >&2
    echo -e "\033[0m" >&2

    __start_time__=$SECONDS
}

epilogue() {
    __end_time__=$SECONDS
    __total_time__=$((__end_time__ - __start_time__))

    echo -e "\033[1;30m" >&2
    echo -e "****************************************************************" >&2
    echo -e "* Execution time Information" >&2
    echo -e "****************************************************************" >&2
    echo -e "[$SCRIPT_NAME]: End time - $(date)" >&2
    echo -e "[$SCRIPT_NAME]: Total time - $(date -u -d @$__total_time__ +%H:%M:%S)" >&2
    echo -e "\033[0m" >&2
}

debug "${BASH_SOURCE[0]} sourced"
