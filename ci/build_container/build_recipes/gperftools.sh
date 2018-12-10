#!/bin/bash

set -e

if [[ "${OS}" == "Windows_NT" ]]; then
  exit 0
fi

VERSION=2.7
SHA256=1ee8c8699a0eff6b6a203e59b43330536b22bbcbe6448f54c7091e5efb0763c9

git clone https://github.com/siepkes/gperftools.git
cd gperftools
git checkout gperftools-2.7-solaris-fix 

CXXFLAGS="-fpic"

./autogen.sh
LDFLAGS="-lpthread -lsocket -lnsl" ./configure --prefix="$THIRDPARTY_BUILD" --enable-shared=no --enable-frame-pointers --disable-libunwind --enable-cpu-profiler --enable-heap-profiler --enable-heap-checker --enable-debugalloc
make V=1 install
