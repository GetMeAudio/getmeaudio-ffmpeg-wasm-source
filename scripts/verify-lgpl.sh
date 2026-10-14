#!/bin/bash
# Fails if the built wasm's FFmpeg configuration enables GPL / video-codec libraries, or lacks --disable-gpl / LAME.
# Checks the embedded "configuration:" string and encoder names. (Generic strings such as "x264 - core" also appear in
# FFmpeg's own H.264 *decoder*, so they are not a reliable signal.)
# Usage: bash scripts/verify-lgpl.sh out/dist/esm/ffmpeg-core.wasm
set -eu
f="${1:?path to ffmpeg-core.wasm}"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# Dump printable strings ONCE to a file. (Piping `strings | grep -q` under pipefail is unreliable: grep exits early,
# strings gets SIGPIPE, and the pipeline reports failure even on a match.)
strings -n 6 "$f" > "$tmp"
bad=0
for pat in "--enable-gpl" "--enable-nonfree" "--enable-libx264" "--enable-libx265" "--enable-libvpx" "--enable-libass" "--enable-libzimg" "--enable-libtheora" "--enable-libvorbis" "--enable-libopus" "--enable-libwebp" "libx264 H.264" "libx265 H.265" "x264 - core %d%s" "x265 (build"; do
  if grep -qF -- "$pat" "$tmp"; then echo "FAIL: found '$pat'"; bad=1; fi
done
if ! grep -qF -- "--disable-gpl" "$tmp"; then echo "FAIL: configuration does not show --disable-gpl"; bad=1; fi
if ! grep -qF -- "--enable-libmp3lame" "$tmp"; then echo "FAIL: configuration does not show --enable-libmp3lame"; bad=1; fi
if ! grep -qF "libmp3lame encoder" "$tmp"; then echo "FAIL: libmp3lame missing"; bad=1; fi
grep -m1 -F -- "configuration:" "$tmp" | cut -c1-400 || true
if [ "$bad" = 0 ]; then echo "OK: LGPL-only markers verified for $f"; fi
exit "$bad"
