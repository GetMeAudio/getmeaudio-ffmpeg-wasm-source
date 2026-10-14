#!/bin/bash
# Fails if the built wasm contains GPL / video-codec library markers, or lacks the LGPL licence text.
# Usage: scripts/verify-lgpl.sh out/dist/esm/ffmpeg-core.wasm
set -euo pipefail
f="${1:?path to ffmpeg-core.wasm}"
bad=0
for pat in "--enable-gpl" "terms of the GNU General Public License" "x264 - core" "x265 (build" "libx264" "libx265" "libass" "libvpx" "libzimg"; do
  if strings -n 6 "$f" | grep -qF -- "$pat"; then echo "FAIL: found '$pat'"; bad=1; fi
done
if ! strings -n 6 "$f" | grep -q "GNU Lesser General Public License"; then echo "FAIL: FFmpeg LGPL licence text not found"; bad=1; fi
if ! strings -n 6 "$f" | grep -q "libmp3lame encoder"; then echo "FAIL: libmp3lame missing"; bad=1; fi
strings -n 6 "$f" | grep -E "^--(prefix|disable|enable)" | head -3 || true
[ "$bad" = 0 ] && echo "OK: LGPL-only markers verified for $f"
exit $bad
