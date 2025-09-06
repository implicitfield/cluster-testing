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
# 21
deb http://apt.llvm.org/noble/ llvm-toolchain-noble-21 main
deb-src http://apt.llvm.org/noble/ llvm-toolchain-noble-21 main
EOF
wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | sudo apt-key add -
sudo apt-get update
sudo apt-get install clang-21 llvm-21 lld-21
sudo ln -s /usr/bin/clang-21 /usr/local/bin/clang-21
sudo ln -s /usr/bin/clang++-21 /usr/local/bin/clang++-21
sudo ln -s /usr/bin/clang-21 /usr/local/bin/clang
sudo ln -s /usr/bin/clang++-21 /usr/local/bin/clang++
