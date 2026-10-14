#!/bin/bash
# Configures and builds FFmpeg (libraries only) for WebAssembly. Based on build/ffmpeg.sh at ffmpeg.wasm commit 71aa99d3 (release of @ffmpeg/core 0.12.10).
# Extra flags (e.g. --enable-libmp3lame) are passed in by the Dockerfile.

set -euo pipefail

CONF_FLAGS=(
  --target-os=none              # disable target specific configs
  --arch=x86_32                 # use x86_32 arch
  --enable-cross-compile        # use cross compile configs
  --disable-asm                 # disable asm
  --disable-stripping           # disable stripping as it won't work
  --disable-programs            # disable ffmpeg, ffprobe and ffplay build
  --disable-doc                 # disable doc build
  --disable-debug               # disable debug mode
  --disable-runtime-cpudetect   # disable cpu detection
  --disable-autodetect          # disable env auto detect

  # --- GetMeAudio changes vs upstream: LGPL-only, audio-only encoders ---
  --disable-gpl                 # never GPL (upstream passed --enable-gpl)
  --disable-nonfree             # never non-redistributable
  --disable-network             # no network protocols needed in the browser
  --disable-encoders            # drop every encoder (incl. native AAC/MPEG-4 etc.) ...
  --enable-encoder=libmp3lame,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s32le,pcm_f32le   # ... then re-enable only MP3 + PCM/WAV

  # assign toolchains and extra flags
  --nm=emnm
  --ar=emar
  --ranlib=emranlib
  --cc=emcc
  --cxx=em++
  --objcc=emcc
  --dep-cc=emcc
  --extra-cflags="$CFLAGS"
  --extra-cxxflags="$CXXFLAGS"

  # disable thread when FFMPEG_ST is NOT defined
  ${FFMPEG_ST:+ --disable-pthreads --disable-w32threads --disable-os2threads}
)

emconfigure ./configure "${CONF_FLAGS[@]}" $@
emmake make -j
