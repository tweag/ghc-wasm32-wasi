#!/usr/bin/env bash

set -euo pipefail

readonly PREFIX="${PREFIX:-$HOME/.ghc-wasm32-wasi}"

rm -rf "$PREFIX"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

pushd "$workdir"

curl -L https://nightly.link/WebAssembly/wasi-sdk/workflows/main/main/dist-ubuntu-latest.zip -O
unzip dist-ubuntu-latest.zip
mkdir -p "$PREFIX/wasi-sdk"
tar xzf wasi-sdk-*.tar.gz --strip-components=1 -C "$PREFIX/wasi-sdk"

curl -L https://nightly.link/tweag/libffi-wasm32/workflows/shell/master/out.zip -O
unzip out.zip
cp include/*.h "$PREFIX/wasi-sdk/share/wasi-sysroot/include"
cp lib/*.a "$PREFIX/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

mkdir "$PREFIX/ghc"
curl -L https://gitlab.haskell.org/TerrorJack/ghc/-/jobs/artifacts/wasm32-wasi/raw/ghc-wasm32-wasi.tar.xz?job=wasm32-wasi-bindist | tar xJ --strip-components=1 -C "$PREFIX/ghc"
pushd "$PREFIX/ghc"
./configure \
  AR="$PREFIX/wasi-sdk/bin/llvm-ar" \
  CC="$PREFIX/wasi-sdk/bin/clang" \
  CXX="$PREFIX/wasi-sdk/bin/clang++" \
  LD="$PREFIX/wasi-sdk/bin/wasm-ld" \
  RANLIB="$PREFIX/wasi-sdk/bin/llvm-ranlib" \
  STRIP="$PREFIX/wasi-sdk/bin/llvm-strip" \
  CONF_CC_OPTS_STAGE2="-O3 -mmutable-globals -mnontrapping-fptoint -mreference-types -msign-ext" \
  CONF_CXX_OPTS_STAGE2="-fno-exceptions -O3 -mmutable-globals -mnontrapping-fptoint -mreference-types -msign-ext" \
  CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--error-limit=0,--growable-table,--stack-first -Wno-unused-command-line-argument" \
  --host=x86_64-linux \
  --target=wasm32-wasi
make lib/settings
./bin/wasm32-wasi-ghc-pkg recache
popd

popd

"$PREFIX/ghc/bin/wasm32-wasi-ghc" --info

echo "Everything set up in $PREFIX."
echo "Call $PREFIX/ghc/bin/wasm32-wasi-ghc to get started."
