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

"$REPO/autogen/wasmtime.sh" > bins-x86_64-linux.zip
unzip bins-x86_64-linux.zip
mkdir -p "$PREFIX/wasmtime/bin"
tar xJf wasmtime-*-x86_64-linux.tar.xz --strip-components=1 -C "$PREFIX/wasmtime/bin" --wildcards '*/wasmtime'

"$REPO/autogen/cabal.sh" > cabal-Linux-8.10.7.zip
unzip cabal-Linux-8.10.7.zip
mkdir -p "$PREFIX/cabal/bin"
tar xf cabal-head.tar -C "$PREFIX/cabal/bin"

"$REPO/autogen/binaryen.sh" > build-ubuntu-latest.zip
mkdir "$PREFIX/binaryen"
unzip build-ubuntu-latest.zip -d "$PREFIX/binaryen"
chmod +x "$PREFIX"/binaryen/bin/*

mkdir "$PREFIX/wabt"
curl -L https://github.com/WebAssembly/wabt/releases/download/1.0.29/wabt-1.0.29-ubuntu.tar.gz | tar xz --strip-components=1 -C "$PREFIX/wabt"

mkdir -p "$PREFIX/qemu-system-wasm32/bin"
cc \
  -DWASMTIME="\"$PREFIX/wasmtime/bin/wasmtime\"" \
  -Wall \
  -Wextra \
  -O3 \
  -o "$PREFIX/qemu-system-wasm32/bin/qemu-system-wasm32" \
  "$REPO/cbits/qemu-system-wasm32.c"

mkdir -p "$PREFIX/wasmtime-run/bin"
echo "#!/bin/sh" >> "$PREFIX/wasmtime-run/bin/wasmtime-run"
echo "exec proot -q $PREFIX/qemu-system-wasm32/bin/qemu-system-wasm32" '${1+"$@"}' >> "$PREFIX/wasmtime-run/bin/wasmtime-run"
chmod +x "$PREFIX/wasmtime-run/bin/wasmtime-run"

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

mkdir -p "$PREFIX/wasm32-wasi-cabal/bin"
echo "#!/bin/sh" >> "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"
echo \
  "CABAL_DIR=$PREFIX/.cabal" \
  "exec" \
  "$PREFIX/cabal/bin/cabal" \
  "--with-compiler=$PREFIX/ghc-wasm32-wasi/bin/wasm32-wasi-ghc" \
  "--with-hc-pkg=$PREFIX/ghc-wasm32-wasi/bin/wasm32-wasi-ghc-pkg" \
  "--with-hsc2hs=$PREFIX/ghc-wasm32-wasi/bin/wasm32-wasi-hsc2hs" \
  '${1+"$@"}' >> "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"
chmod +x "$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal"

"$PREFIX/wasm32-wasi-cabal/bin/wasm32-wasi-cabal" update

echo "export PATH=$PREFIX/wasm32-wasi-cabal/bin:$PREFIX/ghc-wasm32-wasi/bin:$PREFIX/wasi-sdk/bin:$PREFIX/wasmtime-run/bin:$PREFIX/wasmtime/bin:$PREFIX/binaryen/bin:$PREFIX/wabt/bin:\$PATH" > "$PREFIX/env"

popd

echo "Everything set up in $PREFIX."
echo "Run 'source '$PREFIX/env' to add tools to your PATH."
