typeset -U PATH path
path=("$HOME/.local/bin" "$HOME/.cargo/bin" "$path[@]")

if [[ -d "/opt/TeXLive/bin/x86_64-pc-linux-gnu" ]]; then
    path+=("/opt/TeXLive/bin/x86_64-pc-linux-gnu")
fi

export PATH
