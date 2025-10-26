#!/usr/bin/env bash
#
# update-config.sh
#

set -e

pushd zsh
./oh-my-zsh.sh
popd

ln -vrsf nano/.nanorc ~/.nanorc
ln -vrsf git/.gitconfig ~/.gitconfig
