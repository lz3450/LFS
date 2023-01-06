#!/bin/bash

# grml-zsh-config
wget -O rootfs/root/.zshrc https://git.grml.org/f/grml-etc-core/etc/zsh/zshrc
wget -O rootfs/root/.zsh-autosuggestions.zsh https://raw.githubusercontent.com/zsh-users/zsh-autosuggestions/master/zsh-autosuggestions.zsh
wget -O rootfs/root/.zsh-syntax-highlighting.zsh https://raw.githubusercontent.com/zsh-users/zsh-syntax-highlighting/master/zsh-syntax-highlighting.zsh
echo 'source /root/.zsh-syntax-highlighting.zsh' >> rootfs/root/.zshrc
echo 'source /root/.zsh-autosuggestions.zsh' >> rootfs/root/.zshrc
