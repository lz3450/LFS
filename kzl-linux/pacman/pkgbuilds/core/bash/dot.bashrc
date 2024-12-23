# ~/.bashrc

# If not running interactively, don't do anything
if [[ $- != *i* ]]; then
    return
fi

# Source global definitions
if [[ -f /etc/bashrc ]]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin" ]]; then
    PATH="$HOME/.local/bin:$PATH"
fi
export PATH

alias ls='ls --color=auto'
alias grep='grep --color=auto'
PS1='[\u@\h \W]\$ '
