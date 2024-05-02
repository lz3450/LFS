export ROOTDIR=SVF_DIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P)"
echo "ROOTDIR=$SVF_DIR"
export PATH=$ROOTDIR/scripts:$PATH
