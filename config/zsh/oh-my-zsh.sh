#!/bin/bash

set -e
set -u

plugin_rootdir="$HOME/.oh-my-zsh/custom/plugins"

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

tmpdir=/tmp/zsh-syntax-highlighting
rm -rf "$tmpdir"
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$tmpdir"
pushd "$tmpdir"
mkdir -p "$plugin_rootdir"/zsh-syntax-highlighting
make
make \
    PREFIX="$plugin_rootdir"/zsh-syntax-highlighting/ \
    SHARE_DIR="$plugin_rootdir"/zsh-syntax-highlighting/ \
    DOC_DIR="$plugin_rootdir"/zsh-syntax-highlighting/doc \
    install
install -Dm644 zsh-syntax-highlighting.plugin.zsh -t "$plugin_rootdir"/zsh-syntax-highlighting/
popd
rm -rf "$tmpdir"


tmpdir=/tmp/zsh-autosuggestions
rm -rf "$tmpdir"
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$tmpdir"
pushd "$tmpdir"
mkdir -p "$plugin_rootdir"/zsh-autosuggestions
make
install -Dm644 zsh-autosuggestions{,.plugin}.zsh -t "$plugin_rootdir"/zsh-autosuggestions/
popd
rm -rf "$tmpdir"

rm -rf "$plugin_rootdir"/zsh-syntax-highlighting/doc

cp ~/.zshrc .zshrc.orig
cp .zshrc ~/.zshrc
