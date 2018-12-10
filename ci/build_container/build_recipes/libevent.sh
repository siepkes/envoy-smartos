#!/bin/bash

set -e

# Since we are bumping into this issue: https://github.com/libevent/libevent/issues/615
# We need this patch: https://github.com/libevent/libevent/commit/266f43af7798befa3d27bfabaa9ae699259c3924
# Now that Envoy uses CMake we've also bumped into this: https://github.com/libevent/libevent/issues/463
# There is no stable release (yet) with this fix.
git clone https://github.com/siepkes/libevent.git libevent
cd libevent
git checkout patches-2.1

./autogen.sh

mkdir build
cd build

# libevent defaults CMAKE_BUILD_TYPE to Release
build_type=Release
if [[ "${OS}" == "Windows_NT" ]]; then
  # On Windows, every object file in the final executable needs to be compiled to use the
  # same version of the C Runtime Library. If Envoy is built with '-c dbg', then it will
  # use the Debug C Runtime Library. Setting CMAKE_BUILD_TYPE to Debug will cause libevent
  # to use the debug version as well
  # TODO: when '-c fastbuild' and '-c opt' work for Windows builds, set this appropriately
  build_type=Debug
fi

# Samples don't link on Illumos due to https://github.com/libevent/libevent/issues/615
cmake -G "Ninja" \
  -DEVENT__LIBRARY_TYPE:STRING=STATIC \
  -DCMAKE_INSTALL_PREFIX="$THIRDPARTY_BUILD" \
  -DEVENT__DISABLE_OPENSSL:BOOL=on \
  -DEVENT__DISABLE_REGRESS:BOOL=on \
  -DEVENT__DISABLE_SAMPLES:BOOL=on \
  -DCMAKE_BUILD_TYPE="$build_type" \
  ..
ninja
ninja install

if [[ "${OS}" == "Windows_NT" ]]; then
  cp "CMakeFiles/event.dir/event.pdb" "$THIRDPARTY_BUILD/lib/event.pdb"
fi
