#!/bin/bash

. /etc/os-release

pkgs=(
    "libexpat1-dev"
    "libffi-dev"
    "libbz2-dev"
    "libncurses-dev"
    "libgdbm-compat-dev"
    "libgdbm-dev"
    "tcl-dev"
    "tk-dev"
    "libsqlite3-dev"
    "libedit-dev"
    "valgrind"
)

# case $UBUNTU_CODENAME in
#     "jammy")
#         pkgs+=("libmpdec-dev")
#         ;;
#     "noble")
#         ;;
#     *)
#         ;;
# esac

sudo apt install "${pkgs[@]}"
