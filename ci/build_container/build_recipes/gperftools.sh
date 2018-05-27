#!/bin/bash

set -e

VERSION=2.7

git clone https://github.com/siepkes/gperftools.git
cd gperftools
git checkout gperftools-2.7-solaris-fix 

CXXFLAGS="-fpic"

./autogen.sh
LDFLAGS="-lpthread -lsocket -lnsl" ./configure --prefix="$THIRDPARTY_BUILD" --enable-shared=no --enable-frame-pointers --disable-libunwind --enable-cpu-profiler --enable-heap-profiler --enable-heap-checker --enable-debugalloc
make V=1 install
