#!/usr/bin/env bash
set -euo pipefail

# Build Chocolate Doom as a WebAssembly target using Emscripten + CMake.
# This script assumes you have emscripten tools (emcmake/emmake) in PATH.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$ROOT_DIR/chocolate-doom"
BUILD_DIR="$SRC_DIR/build-emscripten"

# Use a local, writable Emscripten cache and explicitly disable frozen cache.
# This avoids EMCC_FROZEN_CACHE errors when using the SDL2 ports.
CACHE_DIR="$ROOT_DIR/.emscripten_cache"
mkdir -p "$CACHE_DIR"
export EM_CACHE="$CACHE_DIR"
export EMCC_FROZEN_CACHE=0

if [ ! -d "$SRC_DIR" ]; then
  echo "Expected Chocolate Doom source tree at: $SRC_DIR" >&2
  exit 1
fi

for bin in emcmake emmake cmake; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    echo "Required tool not found in PATH: $bin" >&2
    echo "Make sure your Emscripten SDK environment is activated." >&2
    exit 1
  fi
done

mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

echo "[build-wasm] Configuring CMake project for Emscripten in: $BUILD_DIR" 
emcmake cmake "$SRC_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DENABLE_SDL2_NET=ON \
  -DENABLE_SDL2_MIXER=ON

# Prefer ninja if available; otherwise fall back to make.
if command -v ninja >/dev/null 2>&1; then
  echo "[build-wasm] Building with ninja (Emscripten)" 
  emmake ninja chocolate-doom
else
  echo "[build-wasm] Building with make (Emscripten)" 
  emmake make chocolate-doom
fi

# Try to locate the generated JS and WASM artifacts.
JS_OUT="$(find "$BUILD_DIR" -maxdepth 5 -type f -name 'chocolate-doom.js' 2>/dev/null | head -n 1 || true)"
WASM_OUT="$(find "$BUILD_DIR" -maxdepth 5 -type f -name 'chocolate-doom.wasm' 2>/dev/null | head -n 1 || true)"

if [ -z "$JS_OUT" ] || [ -z "$WASM_OUT" ]; then
  echo "[build-wasm] Build completed, but did not find chocolate-doom.js/.wasm under $BUILD_DIR" >&2
  echo "Inspect the build directory and adjust this script if the target name or paths differ." >&2
  exit 1
fi

echo "[build-wasm] Build successful." 
echo "[build-wasm] JavaScript glue: $JS_OUT" 
echo "[build-wasm] WebAssembly module: $WASM_OUT" 

echo
echo "You can now feed these paths into prepare_chocolate_doom_triplet.sh, e.g.:" 
echo "  ./prepare_chocolate_doom_triplet.sh /path/to/doom1.wad \"$JS_OUT\" \"$WASM_OUT\"" 
