#!/usr/bin/env bash

set -euo pipefail

curl -O 'https://mirror.rackspace.com/archlinux/iso/2025.07.01/archlinux-bootstrap-x86_64.tar.zst'
if [[ "$(b2sum archlinux-bootstrap-x86_64.tar.zst | cut -d ' ' -f1)" != "f73754445f75ed2bb4831a35e4312602cf7223058ca4708ea0755619c8e446c535bac32159507f209d52a98330251a506136a9b29d0b5d94679c2c933b0fa046" ]]; then
  echo "Checksum mismatch"
  exit 1
fi
sudo tar -xf archlinux-bootstrap-x86_64.tar.zst --numeric-owner
echo 'Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch' | sudo tee root.x86_64/etc/pacman.d/mirrorlist

sudo mount --bind $PWD/root.x86_64 $PWD/root.x86_64

cat << 'EOF' | sudo tee root.x86_64/root/create-user.sh
#!/bin/bash
set -euo pipefail
pacman-key --init
pacman-key --populate
pacman -Syu --noconfirm
pacman -S --noconfirm base-devel distcc gtk3 nss alsa-lib xdg-utils libxss libcups libgcrypt ttf-liberation systemd dbus libpulse pciutils libva libffi desktop-file-utils hicolor-icon-theme python gn ninja clang lld gperf nodejs pipewire rust rust-bindgen qt5-base qt6-base java-runtime-headless git libwebp minizip libxslt
useradd -m build
chown -R build /home/build
echo 'MAKEFLAGS="-j96"' >> /etc/makepkg.conf
ln -s /usr/bin/clang /usr/local/bin/clang
ln -s /usr/bin/clang++ /usr/local/bin/clang++
mkdir -p /usr/local/lib
ln -s /usr/lib/clang /usr/local/lib/clang
EOF
sudo chmod +x root.x86_64/root/create-user.sh
sudo arch-chroot $PWD/root.x86_64 "/root/create-user.sh"

sudo cp pkgbuild.patch root.x86_64/home/build
sudo chmod 777 root.x86_64/home/build/pkgbuild.patch

cat << 'EOF' | sudo tee root.x86_64/home/build/build.sh
#!/bin/bash
set -euo pipefail
cd
git clone https://github.com/ungoogled-software/ungoogled-chromium-archlinux.git
cd ungoogled-chromium-archlinux
patch -p1 < ../pkgbuild.patch
makepkg --skippgpcheck
EOF
sudo chmod +x root.x86_64/home/build/build.sh
sudo arch-chroot $PWD/root.x86_64 /usr/bin/su -c /home/build/build.sh - build

# This is really annoying, but I really have no idea where this thing hides the package.
# It's probably in whatever PKGDEST is set to, but at this point, who even knows?
sudo find root.x86_64/home/build -name 'ungoogled-chromium-138*pkg.tar.zst' -exec sh -c "echo {} && cp {} ungoogled-chromium.pkg.tar.zst" \;
sudo chown $(whoami) ungoogled-chromium.pkg.tar.zst
