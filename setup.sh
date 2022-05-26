#!/usr/bin/env bash

set -euo pipefail

readonly BIGNUM_BACKEND="${BIGNUM_BACKEND:-gmp}"
readonly PREFIX="${PREFIX:-$HOME/.ghc-wasm32-wasi}"
readonly REPO=$PWD

rm -rf "$PREFIX"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

pushd "$workdir"

"$REPO/autogen/wasi-sdk.sh" > dist-ubuntu-latest.zip
unzip dist-ubuntu-latest.zip
mkdir -p "$PREFIX/wasi-sdk"
tar xzf wasi-sdk-*.tar.gz --strip-components=1 -C "$PREFIX/wasi-sdk"

"$REPO/autogen/libffi-wasm32.sh" > out.zip
unzip out.zip
cp include/*.h "$PREFIX/wasi-sdk/share/wasi-sysroot/include"
cp lib/*.a "$PREFIX/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

popd

mkdir "$PREFIX/ghc-wasm32-wasi"
"$REPO/autogen/ghc-wasm32-wasi-$BIGNUM_BACKEND.sh" | tar xJ --strip-components=1 -C "$PREFIX/ghc-wasm32-wasi"
pushd "$PREFIX/ghc-wasm32-wasi"
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

"$PREFIX/ghc-wasm32-wasi/bin/wasm32-wasi-ghc" --info

echo "Everything set up in $PREFIX."
echo "Call $PREFIX/ghc-wasm32-wasi/bin/wasm32-wasi-ghc to get started."
