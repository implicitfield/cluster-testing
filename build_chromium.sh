#!/usr/bin/env bash

set -euo pipefail

OUTPUT_PATH="$PWD/ungoogled-chromium.dmg"

git clone https://github.com/ungoogled-software/ungoogled-chromium-macos.git
cd ungoogled-chromium-macos

git submodule init
git submodule update

cd ungoogled-chromium
git pull origin master
cd ..

cp ../preserve-absolute-path-on-apple.patch patches/ungoogled-chromium/macos
cp ../disable-wgnu-line-marker.patch patches/ungoogled-chromium/macos
echo "ungoogled-chromium/macos/preserve-absolute-path-on-apple.patch" >> patches/series
echo "ungoogled-chromium/macos/disable-wgnu-line-marker.patch" >> patches/series

export DISTCC_HOSTS="localhost/3 --localslots_cpp/$(($1 * 6))"
for i in $(seq 1 $1); do
  export DISTCC_HOSTS="$DISTCC_HOSTS 192.168.166.$(($i + 1))/5"
done

gsed 's/symbol_level=1/symbol_level=0/' -i flags.macos.gn

cat << EOF >> flags.macos.gn
clang_base_path = "/usr/local"
cc_wrapper = "env DISTCC_HOSTS='$DISTCC_HOSTS' distcc"
enable_stripping = false
enable_dsyms = false
swift_whole_module_optimization = 0
use_thin_lto = false
EOF

JOBS=$(((4 + ($1 * 5)) * 2))
gsed "s/ninja/ninja -j$JOBS/" -i build.sh
gsed '/sign_and_package_app/d' -i build.sh
cat << EOF >> build.sh
xattr -cs out/Default/Chromium.app
codesign --force --deep --sign - out/Default/Chromium.app
chrome/installer/mac/pkg-dmg \
  --sourcefile --source out/Default/Chromium.app \
  --target "$OUTPUT_PATH" \
  --volname Chromium --symlink /Applications:/Applications \
  --format UDBZ --verbosity 2
EOF

export SDKROOT="$(xcrun --show-sdk-path)"
./build.sh -d arm64
