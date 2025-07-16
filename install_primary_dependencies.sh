#!/usr/bin/env bash

set -euo pipefail

sudo apt-get install nmap wireguard stun-client asciidoc-base

git clone https://gitlab.archlinux.org/archlinux/arch-install-scripts.git
cd arch-install-scripts
make -j$(nproc)
sudo make install
