#!/usr/bin/env bash
# Builds LibreOffice core for Android (one ABI) from a checkout of https://github.com/LibreOffice/core.
# Usage: build-core.sh <lo-checkout> <abi: arm64-v8a|armeabi-v7a|x86_64>
# Needs ANDROID_HOME (SDK) and ANDROID_NDK (NDK 27-29; 28.x recommended for 16 KB pages).
# Disk: about 40 GB for one ABI (release, no symbols). Time: 1.5-3 h on 16 cores without ccache.
set -euo pipefail
LO="$(cd "$1" && pwd)"
ABI="$2"
HERE="$(cd "$(dirname "$0")" && pwd)"
case "$ABI" in
  arm64-v8a) DISTRO=LibreOfficeAndroidAarch64 ;;
  armeabi-v7a) DISTRO=LibreOfficeAndroid ;;
  x86_64) DISTRO=LibreOfficeAndroidX86_64 ;;
  *) echo "unknown ABI $ABI" >&2; exit 2 ;;
esac
sed -e "s|@ABI_DISTRO@|$DISTRO|" -e "s|@ANDROID_SDK@|$ANDROID_HOME|" -e "s|@ANDROID_NDK@|$ANDROID_NDK|" \
  "$HERE/autogen.input.in" | grep -v '^#' > "$LO/autogen.input"
cd "$LO"
./autogen.sh
# Top-level make builds the static libraries, links liblo-native-code.so (android/Bootstrap/Makefile.shared)
# and assembles LibreOffice's own Android viewer (stripped UI) with its assets, which harvest.sh reads.
make -j"$(nproc)"
ls -la android/source/build/outputs/apk/*/*/ || true
