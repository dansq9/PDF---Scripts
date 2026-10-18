#!/usr/bin/env bash
# Takes the engine out of a finished LibreOffice Android build: native libraries, the assets LibreOffice
# reads at run time, and its licence list. Strips, checks 16 KB alignment, measures.
# Usage: harvest.sh <lo-checkout> <abi> <out-dir>
# Out: <out>/jniLibs/<abi>/*.so, <out>/assets/**, <out>/LICENSE.txt, <out>/sizes.tsv, <out>/sizes.md
set -euo pipefail
LO="$(cd "$1" && pwd)"; ABI="$2"; OUT="$3"
NDK_BIN="$(echo "$ANDROID_NDK"/toolchains/llvm/prebuilt/*/bin)"
STRIP="$NDK_BIN/llvm-strip"; READELF="$NDK_BIN/llvm-readelf"
APK="$(ls "$LO"/android/source/build/outputs/apk/*/*/*.apk | grep -i release | head -1)"
echo "Harvesting from $APK"
rm -rf "$OUT"; mkdir -p "$OUT/jniLibs/$ABI" "$OUT/assets"
TMP="$(mktemp -d)"; unzip -q "$APK" 'lib/*' 'assets/*' -d "$TMP"
cp "$TMP/lib/$ABI/"*.so "$OUT/jniLibs/$ABI/"
cp -r "$TMP/assets/." "$OUT/assets/"
cp "$LO/instdir/LICENSE" "$OUT/LICENSE.txt" 2>/dev/null || cp "$LO/instdir/LICENSE.html" "$OUT/LICENSE.html"
# Gentium is not a stand-in for any Microsoft font; Carlito, Caladea, Liberation and OpenSymbol stay.
rm -f "$OUT"/assets/unpack/user/fonts/Gen*.ttf
fail=0
for so in "$OUT/jniLibs/$ABI/"*.so; do
  "$STRIP" --strip-unneeded "$so"
  # Every LOAD segment must be aligned to 2**14 (16 KB) or more.
  for a in $("$READELF" -lW "$so" | awk '$1=="LOAD"{print $NF}'); do
    if [ $((a)) -lt 16384 ]; then echo "NOT 16 KB ALIGNED: $(basename "$so") (LOAD align $a)"; fail=1; fi
  done
done
{
  printf 'file\tbytes\tdeflated\n'
  for f in "$OUT/jniLibs/$ABI/"*.so; do printf '%s\t%s\t%s\n' "$(basename "$f")" "$(stat -c%s "$f")" "$(gzip -9c "$f" | wc -c)"; done
  printf 'assets/\t%s\t%s\n' "$(du -sb "$OUT/assets" | cut -f1)" "$(tar -C "$OUT" -cf - assets | gzip -9 | wc -c)"
  printf 'fonts\t%s\t-\n' "$(du -cb "$OUT"/assets/unpack/user/fonts/* 2>/dev/null | tail -1 | cut -f1)"
} > "$OUT/sizes.tsv"
awk -F'\t' 'NR==1{print "| file | bytes | deflated |\n|---|---:|---:|"; next} {print "| "$1" | "$2" | "$3" |"; if ($1!="fonts") {t+=$2; d+=$3}} END{print "| **total** | "t" | "d" |"}' "$OUT/sizes.tsv" > "$OUT/sizes.md"
cat "$OUT/sizes.md"
# Assets must be stored uncompressed in the module (LibreOffice maps them in place): see exactconvert/build.gradle.kts.
exit $fail
