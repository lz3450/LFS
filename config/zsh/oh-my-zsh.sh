#!/bin/bash

cd
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
cd .oh-my-zsh/custom/plugins
git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git
git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git
cd
sed -e "/^ZSH_THEME/s/\"robbyrussell\"/random/" \
    -e "/^plugins=/s/git/zsh-syntax-highlighting zsh-autosuggestions archlinux git vscode python tmux/" \
    -i .zshrc