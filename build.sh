#!/usr/bin/env bash

set -euo pipefail

export CC="distcc clang -target arm64-apple-darwin24.5.0"
export CXX="distcc clang++ -target arm64-apple-darwin24.5.0"
export DISTCC_HOSTS="localhost/4 192.168.166.2/5"
export SDKROOT="$(xcrun --show-sdk-path)"
cd llvm-project
patch -p1 < ../clang-actually-disable-pedantic.patch
cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DLLVM_ENABLE_PROJECTS="llvm;clang;clang-tools-extra;openmp;bolt;lld;lldb;polly;mlir;flang" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
        -DLLVM_ENABLE_PEDANTIC=OFF \
        llvm
ninja -j18
mkdir LLVM-20.1.7
DESTDIR=$PWD/LLVM-20.1.7 ninja install
tar -cf - LLVM-20.1.7 | xz -9 -T$(nproc) > LLVM-20.1.7.tar.xz
