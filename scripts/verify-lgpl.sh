#!/bin/bash
# Fails if the built wasm contains GPL / video-codec library markers, or lacks the LGPL licence text / LAME.
# Usage: bash scripts/verify-lgpl.sh out/dist/esm/ffmpeg-core.wasm
set -eu
f="${1:?path to ffmpeg-core.wasm}"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# Dump printable strings ONCE to a file. (Piping `strings | grep -q` under pipefail is unreliable: grep exits early,
# strings gets SIGPIPE, and the pipeline reports failure even on a match.)
strings -n 6 "$f" > "$tmp"
bad=0
for pat in "--enable-gpl" "terms of the GNU General Public License" "x264 - core" "x265 (build" "libx264" "libx265" "libass" "libvpx" "libzimg"; do
  if grep -qF -- "$pat" "$tmp"; then echo "FAIL: found '$pat'"; bad=1; fi
done
if ! grep -qF "GNU Lesser General Public License" "$tmp"; then echo "FAIL: FFmpeg LGPL licence text not found"; bad=1; fi
if ! grep -qF "libmp3lame encoder" "$tmp"; then echo "FAIL: libmp3lame missing"; bad=1; fi
grep -E "^--(prefix|disable|enable)" "$tmp" | head -3 || true
if [ "$bad" = 0 ]; then echo "OK: LGPL-only markers verified for $f"; fi
exit "$bad"
