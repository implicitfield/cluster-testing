#!/bin/bash
brew install wireguard-go wireguard-tools nmap distcc

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
curl -OL https://github.com/implicitfield/llvm-macos-buildbot/releases/download/20.1.7-arm64/clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz
if [[ $(shasum -a 512 clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz) != "3578035dd978a311178ba257c83689a8233c91a8a2eb6bf5d502a092477e58f01d642cc5766463645d140d9b3358fed37af2c59fb26233e94faa1c709155be59  clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz" ]]; then
  exit 1
fi
tar -xf clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz
sudo cp -r clang+llvm-20.1.7-arm64-apple-darwin21.0/* /usr/local/
sudo ln -s $(which clang++) $(which clang++)-20
sudo xcode-select --switch /Applications/Xcode_16.4.app
