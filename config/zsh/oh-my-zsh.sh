#!/bin/bash

set -e
set -u

ohmyzsh_dir="$HOME/.oh-my-zsh"
plugin_rootdir="$HOME/.oh-my-zsh/custom/plugins"
log_dir="$HOME/log"


install_ohmyzsh() {
    if [ -d "$ohmyzsh_dir" ]; then
        rm -vrf "$ohmyzsh_dir"
    fi

    export RUNZSH="no"
    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh-syntax-highlighting() {
    tmpdir=/tmp/zsh-syntax-highlighting
    rm -vrf "$tmpdir"
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
    rm -vrf "$tmpdir"
}

install_zsh-autosuggestions() {
    tmpdir=/tmp/zsh-autosuggestions
    rm -vrf "$tmpdir"
    git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$tmpdir"
    pushd "$tmpdir"
    mkdir -p "$plugin_rootdir"/zsh-autosuggestions
    make
    install -Dm644 zsh-autosuggestions{,.plugin}.zsh -t "$plugin_rootdir"/zsh-autosuggestions/
    popd
    rm -vrf "$tmpdir"
    rm -vrf "$plugin_rootdir"/zsh-syntax-highlighting/doc
}

################################################################################
mkdir -p "$log_dir"
install_ohmyzsh &> "$log_dir/oh-my-zsh.log"
install_zsh-syntax-highlighting &> "$log_dir/zsh-syntax-highlighting.log"
install_zsh-autosuggestions &> "$log_dir/zsh-autosuggestions.log"

cp ~/.zshrc .zshrc.orig
ln -srfv .zshrc ~
ln -srfv .zshenv ~
