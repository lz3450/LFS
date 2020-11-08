# environment variables
cat > ~/.zshenv << EOF
typeset -U PATH path
path=("$HOME/.local/bin" "\$path[@]")
export PATH
EOF

# other settings
