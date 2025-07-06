#!/usr/bin/env bash

set -euo pipefail

sudo apt-get install nmap wireguard distcc stun-client
cat << EOF | sudo tee -a /etc/apt/sources.list
deb http://apt.llvm.org/noble/ llvm-toolchain-noble main
deb-src http://apt.llvm.org/noble/ llvm-toolchain-noble main
# 19
deb http://apt.llvm.org/noble/ llvm-toolchain-noble-19 main
deb-src http://apt.llvm.org/noble/ llvm-toolchain-noble-19 main
# 20
deb http://apt.llvm.org/noble/ llvm-toolchain-noble-20 main
deb-src http://apt.llvm.org/noble/ llvm-toolchain-noble-20 main
EOF
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install clang-20 llvm-20 lld-20
sudo ln -s /usr/bin/clang-20 /usr/local/bin/clang-20
sudo ln -s /usr/bin/clang++-20 /usr/local/bin/clang++-20
