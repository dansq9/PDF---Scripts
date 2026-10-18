# Papers · LibreOffice engine build

Build scripts for the LibreOffice engine that the Papers Android app downloads for **Exact conversion**
(Word, Excel, PowerPoint and OpenDocument to PDF, on the phone and offline). This repository holds no app
code; it is public so the build runs on GitHub's free standard runners.

## Run a build

Actions → **Build LibreOffice engine (Android)** → Run workflow. Pick the LibreOffice tag and ABI
(`arm64-v8a` ships; `x86_64` is for emulators).

- A first build may pass the 6-hour job limit on a free 4-core runner. The compiler cache is saved even
  when a run times out, so run it again and it resumes; later builds take much less.
- On success the workflow publishes a release `engine-<version>-<abi>-<run>` with
  `engine-<abi>.tar.zst`, its SHA-256 and the size table.
- A monthly scheduled run rebuilds the tag in the `LIBREOFFICE_TAG` repository variable (bump it to pick
  up LibreOffice security fixes).

## Use the engine in the app

In the app repository: `scripts/libreoffice/install-engine.sh <url-or-dir>` with the release asset URL
(or an unpacked folder), then `cd android && ./gradlew bundleRelease`.

## What the scripts do

- `scripts/autogen.input.in`: LibreOffice configure options for a headless Android converter
  (no UI, no extensions, no dictionaries; 16 KB-aligned libraries for Android 15+).
- `scripts/build-core.sh <lo-checkout> <abi>`: configures and builds LibreOffice core with the NDK.
- `scripts/harvest.sh <lo-checkout> <abi> <out>`: takes the native libraries, run-time assets and licence
  list out of the build, strips them, checks 16 KB alignment and measures sizes.

## Licence

The scripts in this repository: MPL 2.0. The engine is LibreOffice (MPL 2.0), built **unchanged** from the
upstream tag named in each release; its full licence list ships inside the archive as `LICENSE.txt`. If
LibreOffice is ever patched for Papers, the patches are published here, as MPL 2.0 requires.
