#!/bin/bash

LLVM_VERSION=21.1.0

brew install wireguard-go wireguard-tools nmap distcc gnu-sed coreutils

# stund isn't (understandably) in homebrew, because it doesn't build on macOS as-is.
curl -OL 'https://downloads.sourceforge.net/project/stun/stun/0.97/stund-0.97.tgz'
if [[ $(shasum -a 512 stund-0.97.tgz) != "8f32d4fadf7264967a8cdabf410b9cd495e1f4dc6198d5efe07559996697db088a8a6b1b5fd0814c1a04fe8c17c866256d6a59b719a153fd23c26939d3c6bc1a  stund-0.97.tgz" ]]; then
  exit 1
fi
tar -xf stund-0.97.tgz
cd stund
patch -p1 < ../fix-stund-macos-build.patch
make client
sudo cp client /usr/local/bin/stun
cd ..
# This should match the version that the auxiliary servers use.
curl -OL https://github.com/implicitfield/llvm-macos-buildbot/releases/download/$LLVM_VERSION-arm64/clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz
if [[ $(shasum -a 512 clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz) != "da21c5f7d77687136f3e198be844a07cf60df7d1f39d1ae4a3e4881eeb1c20831ede87c3a4a781d822b167307170af3d1236a1b9eb910eb0ebbd425a9d0eb8ae  clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz" ]]; then
  exit 1
fi
tar -xf clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz
sudo cp -r clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0/* /usr/local/
sudo ln -s $(which clang++) $(which clang++)-21
sudo xcode-select --switch /Applications/Xcode_16.4.app
