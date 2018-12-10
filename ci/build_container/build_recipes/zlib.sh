#!/bin/bash

set -e

# We need a fix to prevent the '--version-script' flag from being
# set on the linker in CMakeLists.txt.
git clone https://github.com/siepkes/zlib.git
cd zlib
git checkout 28aa7820d3875973a45027c06682df756e5566b7

mkdir build
cd build

cmake -G "Ninja" -DCMAKE_INSTALL_PREFIX:PATH="$THIRDPARTY_BUILD" ..
ninja
ninja install

if [[ "${OS}" == "Windows_NT" ]]; then
  cp "CMakeFiles/zlibstatic.dir/zlibstatic.pdb" "$THIRDPARTY_BUILD/lib/zlibstatic.pdb"
fi
