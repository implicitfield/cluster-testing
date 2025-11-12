#!/bin/bash

LLVM_VERSION=21.1.5

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
if [[ $(shasum -a 512 clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz) != "5914bfe5b2a6092d9f0053d65d60dfe245da86a8247a3b6ea7a1adfc388d95ec2018bd8ba927d9cf793fa296b429333b78f318b9e43913bf63eaf36f338e57e6  clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz" ]]; then
  exit 1
fi
tar -xf clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0.tar.xz
sudo cp -r clang+llvm-$LLVM_VERSION-arm64-apple-darwin21.0/* /usr/local/
sudo ln -s $(which clang++) $(which clang++)-21
sudo xcode-select --switch /Applications/Xcode_26.0.app
