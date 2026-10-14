# syntax=docker/dockerfile-upstream:master-labs
#
# LGPL-only FFmpeg WebAssembly core for GetMeAudio. Derived from the Dockerfile of ffmpeg.wasm commit 71aa99d3 (the release of @ffmpeg/core 0.12.10)
# (https://github.com/ffmpegwasm/ffmpeg.wasm/blob/71aa99d37c02a7b4c435275ca9ef50e612f6efa1/Dockerfile, MIT). Differences: x264, x265, libvpx, theora,
# vorbis, opus, ogg, zlib, libwebp, freetype, fribidi, harfbuzz, libass and zimg are NOT built; FFmpeg is configured
# without --enable-gpl and only libmp3lame (LGPL) is linked; every input is pinned to an exact commit.
#
# Build:  docker buildx build --build-arg FFMPEG_ST=yes --build-arg "EXTRA_CFLAGS=-O3 -msimd128" -o ./out .

# Base emsdk image with environment variables.
FROM emscripten/emsdk:3.1.40 AS emsdk-base
ARG EXTRA_CFLAGS
ARG EXTRA_LDFLAGS
ARG FFMPEG_ST
ARG FFMPEG_MT
ENV INSTALL_DIR=/opt
# FFmpeg n5.1.4 (commit below).
ENV FFMPEG_COMMIT=4729204c17f756e186d622060088371d10b34f7e
ENV CFLAGS="-I$INSTALL_DIR/include $CFLAGS $EXTRA_CFLAGS"
ENV CXXFLAGS="$CFLAGS"
ENV LDFLAGS="-L$INSTALL_DIR/lib $LDFLAGS $CFLAGS $EXTRA_LDFLAGS"
ENV EM_PKG_CONFIG_PATH=$EM_PKG_CONFIG_PATH:$INSTALL_DIR/lib/pkgconfig:/emsdk/upstream/emscripten/system/lib/pkgconfig
ENV EM_TOOLCHAIN_FILE=$EMSDK/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake
ENV PKG_CONFIG_PATH=$PKG_CONFIG_PATH:$EM_PKG_CONFIG_PATH
ENV FFMPEG_ST=$FFMPEG_ST
ENV FFMPEG_MT=$FFMPEG_MT
RUN apt-get update && \
      apt-get install -y pkg-config autoconf automake libtool ragel

# Build lame (LGPL MP3 encoder) - ffmpegwasm/lame fork, pinned commit.
FROM emsdk-base AS lame-builder
ENV LAME_COMMIT=2badea1974ae36cb8312afe99cff1e6b3b5decee
ADD https://github.com/ffmpegwasm/lame.git#$LAME_COMMIT /src
COPY build/lame.sh /src/build.sh
RUN bash -x /src/build.sh

# Base ffmpeg image with dependencies and source code populated.
FROM emsdk-base AS ffmpeg-base
RUN embuilder build sdl2 sdl2-mt
ADD https://github.com/FFmpeg/FFmpeg.git#$FFMPEG_COMMIT /src
COPY --from=lame-builder $INSTALL_DIR $INSTALL_DIR

# Build ffmpeg (no --enable-gpl)
FROM ffmpeg-base AS ffmpeg-builder
COPY build/ffmpeg.sh /src/build.sh
RUN bash -x /src/build.sh \
      --enable-libmp3lame

# Build ffmpeg.wasm
FROM ffmpeg-builder AS ffmpeg-wasm-builder
COPY src/bind /src/src/bind
COPY src/fftools /src/src/fftools
COPY build/ffmpeg-wasm.sh build.sh
# libraries to link
ENV FFMPEG_LIBS \
      -lmp3lame
RUN mkdir -p /src/dist/umd && bash -x /src/build.sh \
      ${FFMPEG_LIBS} \
      -o dist/umd/ffmpeg-core.js
RUN mkdir -p /src/dist/esm && bash -x /src/build.sh \
      ${FFMPEG_LIBS} \
      -sEXPORT_ES6 \
      -o dist/esm/ffmpeg-core.js

# Export ffmpeg-core.wasm to dist/
FROM scratch AS exportor
COPY --from=ffmpeg-wasm-builder /src/dist /dist
