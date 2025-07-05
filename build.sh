#!/usr/bin/env bash

set -euo pipefail

export CC="distcc clang -target arm64-apple-darwin24.5.0"
export CXX="distcc clang++ -target arm64-apple-darwin24.5.0"
export DISTCC_HOSTS="localhost/6 10.0.0.2/8"
export SDKROOT="$(xcrun --show-sdk-path)"
cd llvm-project
cmake -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DLLVM_ENABLE_PROJECTS="llvm;clang;clang-tools-extra;openmp;bolt;lld;lldb;polly;mlir;flang" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
        llvm
ninja -j28
mkdir LLVM-20.1.7
DESTDIR=$PWD/LLVM-20.1.7 ninja install
tar -cf - LLVM-20.1.7 | xz -9 -T$(nproc) > LLVM-20.1.7.tar.xz
