#!/bin/bash
brew install wireguard-go wireguard-tools nmap distcc
curl -OL https://github.com/implicitfield/llvm-macos-buildbot/releases/download/20.1.7-arm64/clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz
if [[ $(shasum -a 512 clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz) != "3578035dd978a311178ba257c83689a8233c91a8a2eb6bf5d502a092477e58f01d642cc5766463645d140d9b3358fed37af2c59fb26233e94faa1c709155be59  clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz" ]]; then
  exit 1
fi
tar -xf clang+llvm-20.1.7-arm64-apple-darwin21.0.tar.xz
sudo cp -r clang+llvm-20.1.7-arm64-apple-darwin21.0/* /usr/local/
