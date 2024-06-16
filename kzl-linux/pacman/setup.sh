if [ -n "$BASH_VERSION" ]; then
  export ROOTDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P)"
elif [ -n "$ZSH_VERSION" ]; then
  export ROOTDIR="$(cd -- "$(dirname "${(%):-%x}")" >/dev/null 2>&1; pwd -P)"
else
  echo "Unsupported shell"
fi

echo "ROOTDIR=$ROOTDIR"
export PATH=$ROOTDIR/scripts:$PATH
