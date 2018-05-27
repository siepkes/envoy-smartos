#!/bin/bash

set -e

VERSION=2.6.4

wget -O gperftools-"$VERSION".tar.xz http://misc.serviceplanet.nl/envoy/gperftools/gperftools-illumos-fix-${VERSION}.tar.xz
tar xf gperftools-"$VERSION".tar.xz
cd gperftools

CXXFLAGS="-fpic"

./autogen.sh
LDFLAGS="-lpthread -lsocket -lnsl" ./configure --prefix="$THIRDPARTY_BUILD" --enable-shared=no --enable-frame-pointers --disable-libunwind --enable-cpu-profiler --enable-heap-profiler --enable-heap-checker --enable-debugalloc
make V=1 install
