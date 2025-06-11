if [ -n "$BASH_VERSION" ]; then
  export LFS_PACMAN_ROOT_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" > /dev/null 2>&1; pwd -P)"
elif [ -n "$ZSH_VERSION" ]; then
  export LFS_PACMAN_ROOT_DIR="$(cd -- "$(dirname "${(%):-%x}")" > /dev/null 2>&1; pwd -P)"
else
  echo "Unsupported shell"
fi

echo "LFS_PACMAN_ROOT_DIR=$LFS_PACMAN_ROOT_DIR"
export PATH="$LFS_PACMAN_ROOT_DIR/scripts:$PATH"
