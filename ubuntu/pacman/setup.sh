#!/bin/bash

export ROOTDIR="$(cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1; pwd -P)"
export PATH=$ROOTDIR/scripts:$PATH
