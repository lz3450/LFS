#!/bin/bash

set -e

pushd zsh
./oh-my-zsh.sh
popd

ln -rsfv nano/.nanorc ~/.nanorc
ln -rsfv git/.gitconfig ~/.gitconfig
