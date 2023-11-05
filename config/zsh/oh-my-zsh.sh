#!/bin/bash

set -e
set -u

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sed -e "/^ZSH_THEME/s/\"robbyrussell\"/random/" \
    -e "/^plugins=/s/git/archlinux git vscode python tmux zsh-autosuggestions zsh-syntax-highlighting/" \
    -i ~/.zshrc
