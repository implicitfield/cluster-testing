#!/usr/bin/env bash

set -euo pipefail

export DISTCC_HOSTS="localhost/4"
for i in $(seq 1 $1); do
  export DISTCC_HOSTS="$DISTCC_HOSTS 192.168.166.$(($i + 1))/5"
done
export TARGET="$(clang -v 2>&1 | grep 'Target:' | cut -d ' ' -f2)"
export SDKROOT="$(xcrun --show-sdk-path)"
cd llvm-project
patch -p1 < ../clang-actually-disable-pedantic.patch
cmake -G Ninja \
        -DCMAKE_C_COMPILER_LAUNCHER=distcc \
        -DCMAKE_CXX_COMPILER_LAUNCHER=distcc \
        -DCMAKE_C_COMPILER=clang-20 \
        -DCMAKE_CXX_COMPILER=clang++-20 \
        -DCMAKE_C_FLAGS="-target $TARGET" \
        -DCMAKE_CXX_FLAGS="-target $TARGET" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -DLLVM_ENABLE_PROJECTS="llvm;clang;clang-tools-extra;openmp;bolt;lld;lldb;polly;mlir;flang" \
        -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
        -DLLVM_ENABLE_PEDANTIC=OFF \
        llvm
JOBS=$(((4 + ($1 * 5)) * 2))
echo "Building with $JOBS jobs"
ninja -j$JOBS
mkdir LLVM-20.1.7
DESTDIR=$PWD/LLVM-20.1.7 ninja install
tar -cf - LLVM-20.1.7 | xz -9 -T$(sysctl -n hw.logicalcpu) > ../LLVM-20.1.7.tar.xz
