#!/bin/bash

set -e

# Since we are bumping into this issue: https://github.com/libevent/libevent/issues/615
# We need this patch: https://github.com/libevent/libevent/commit/266f43af7798befa3d27bfabaa9ae699259c3924
# There is no stable release (yet) with this fix.

git clone https://github.com/siepkes/libevent.git libevent
cd libevent
git checkout patches-2.1

./autogen.sh
# Samples don't link on Illumos due to https://github.com/libevent/libevent/issues/615
./configure --prefix="$THIRDPARTY_BUILD" --enable-shared=no --disable-libevent-regress --disable-openssl --disable-samples
make V=1 install
