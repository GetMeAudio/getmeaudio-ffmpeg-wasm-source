# getmeaudio-ffmpeg-wasm-source

Corresponding source and build recipe for the **FFmpeg WebAssembly core** that [getmeaudio.com](https://getmeaudio.com) loads in your browser to encode MP3/WAV files and combine clips.

This is an **LGPL-only** build. It contains FFmpeg and the LAME MP3 encoder, and no GPL code (no x264, x265, libvpx, libass or similar).

## What is in the build

| Component | Version | Licence | Source |
|---|---|---|---|
| FFmpeg libraries (libavcodec, libavformat, libavfilter, libavutil, libswresample, libswscale, libpostproc, libavdevice) | n5.1.4 (commit `4729204c17f756e186d622060088371d10b34f7e`) | LGPL-2.1-or-later | https://github.com/FFmpeg/FFmpeg |
| LAME MP3 encoder (ffmpegwasm fork) | commit `2badea1974ae36cb8312afe99cff1e6b3b5decee` | LGPL-2.0-or-later | https://github.com/ffmpegwasm/lame |
| ffmpeg.wasm command-line glue (`src/fftools`, `src/bind`) | from ffmpeg.wasm v0.12.10 (commit `c3a763857c5e615ae8674715ad5e4f63ff469e9d`) | `src/fftools`: LGPL-2.1-or-later (FFmpeg); `src/bind`: MIT | https://github.com/ffmpegwasm/ffmpeg.wasm |
| Emscripten toolchain | `emscripten/emsdk:3.1.40` (Docker image) | MIT / UIUC | https://github.com/emscripten-core/emsdk |

FFmpeg is configured with `--disable-gpl --disable-nonfree --disable-network`, and only these encoders: `libmp3lame` and `pcm_*` (WAV). It is built single-threaded (no SharedArrayBuffer needed).

This software uses libraries from the FFmpeg project (https://ffmpeg.org) under the LGPLv2.1. It is not endorsed by or affiliated with the FFmpeg project.

## Differences from upstream ffmpeg.wasm v0.12.10

- Removed `--enable-gpl` and every external library except LAME (x264, x265, libvpx, theora, vorbis, opus, ogg, zlib, libwebp, freetype, fribidi, harfbuzz, libass, zimg).
- Added `--disable-gpl --disable-nonfree --disable-network --disable-encoders --enable-encoder=libmp3lame,pcm_*`.
- Pinned FFmpeg and LAME to exact commits.
- `src/bind` and `src/fftools` are unchanged copies from upstream v0.12.10.

See `Dockerfile` and `build/ffmpeg.sh` for the exact recipe.

## Download the exact files we serve

Each [release](../../releases) contains, with `SHA256SUMS.txt`:

- `ffmpeg-core.js` and `ffmpeg-core.wasm` (ESM build, the files getmeaudio.com serves)
- `ffmpeg-core.umd.js` and `ffmpeg-core.umd.wasm`
- the corresponding source: FFmpeg, LAME, and this repository's recipe

## Rebuild it yourself

Requires Docker with buildx.

```bash
docker buildx build \
  --build-arg FFMPEG_ST=yes \
  --build-arg "EXTRA_CFLAGS=-O3 -msimd128" \
  --progress=plain \
  -o ./out .
./scripts/verify-lgpl.sh out/dist/esm/ffmpeg-core.wasm
```

Output is in `out/dist/esm` (and `out/dist/umd`). The GitHub Actions workflow in `.github/workflows/build.yml` does the same and publishes the release.

## Replacing the library (LGPL)

The core is a separate, unobfuscated `.wasm` + `.js` pair loaded by the page as a normal file. To use a modified build, rebuild as above and serve your files in place of ours, for example by loading your own `ffmpeg-core.js` / `ffmpeg-core.wasm` with [`@ffmpeg/ffmpeg`](https://github.com/ffmpegwasm/ffmpeg.wasm) (`ffmpeg.load({ coreURL, wasmURL })`).

## Licences

- FFmpeg libraries: GNU LGPL v2.1 or later (https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html). The licence text is in the FFmpeg source tarball (`COPYING.LGPLv2.1`).
- LAME: GNU LGPL (text in the LAME source tarball, `COPYING`).
- ffmpeg.wasm glue: MIT, see `licenses/ffmpeg.wasm-MIT.txt`.
- The recipe files in this repository (`Dockerfile`, `build/`, `scripts/`, workflow) are derived from ffmpeg.wasm (MIT) and are provided under the same MIT terms.

## Contact

support@getmeaudio.com. If any link here is unavailable and you want a copy of the source, email us and we will provide it.
