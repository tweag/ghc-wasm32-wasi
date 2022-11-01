#!/usr/bin/env bash

set -euo pipefail

readonly BIGNUM_BACKEND="${BIGNUM_BACKEND:-gmp}"
readonly PREFIX="${PREFIX:-$HOME/.ghc-wasm32-wasi-new}"
readonly REPO=$PWD
readonly SKIP_GHC="${SKIP_GHC:-}"

rm -rf "$PREFIX"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

pushd "$workdir"

curl -f -L --retry 5 "$(jq -r '."wasi-sdk".url' "$REPO"/autogen.json)" -o wasi-sdk.zip
unzip wasi-sdk.zip
mkdir -p "$PREFIX/wasi-sdk"
tar xzf wasi-sdk-*.tar.gz --strip-components=1 -C "$PREFIX/wasi-sdk"

curl -f -L --retry 5 "$(jq -r '."libffi-wasm32".url' "$REPO"/autogen.json)" -o libffi-wasm32.zip
unzip libffi-wasm32.zip
cp -a libffi-wasm32/include/. "$PREFIX/wasi-sdk/share/wasi-sysroot/include"
cp -a libffi-wasm32/lib/. "$PREFIX/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

curl -f -L --retry 5 "$(jq -r .deno.url "$REPO"/autogen.json)" -o deno.zip
unzip deno.zip
mkdir -p "$PREFIX/deno/bin"
install -Dm755 deno "$PREFIX/deno/bin"

mkdir -p "$PREFIX/binaryen"
curl -f -L --retry 5 "$(jq -r .binaryen.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/binaryen" --strip-components=1

mkdir -p "$PREFIX/wabt"
curl -f -L --retry 5 "$(jq -r .wabt.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wabt" --strip-components=1

mkdir -p "$PREFIX/wasmtime/bin"
curl -f -L --retry 5 "$(jq -r .wasmtime.url "$REPO"/autogen.json)" | tar xJ -C "$PREFIX/wasmtime/bin" --strip-components=1 --wildcards '*/wasmtime'

mkdir -p "$PREFIX/wasmedge"
curl -f -L --retry 5 "$(jq -r .wasmedge.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wasmedge" --strip-components=1

mkdir -p "$PREFIX/wasmer"
curl -f -L --retry 5 "$(jq -r .wasmer.url "$REPO"/autogen.json)" | tar xz -C "$PREFIX/wasmer"

curl -f -L --retry 5 "$(jq -r .wizer.url "$REPO"/autogen.json)" -o wizer.zip
unzip wizer.zip
mkdir -p "$PREFIX/wizer/bin"
install -Dm755 wizer "$PREFIX/wizer/bin"

mkdir -p "$PREFIX/cabal/bin"
curl -f -L --retry 5 "$(jq -r .cabal.url "$REPO"/autogen.json)" | tar xJ -C "$PREFIX/cabal/bin" 'cabal'

mkdir -p "$PREFIX/proot/bin"
curl -f -L --retry 5 "$(jq -r .proot.url "$REPO"/autogen.json)" -o "$PREFIX/proot/bin/proot"
chmod 755 "$PREFIX/proot/bin/proot"

echo "#!/bin/sh" >> "$PREFIX/add_to_github_path.sh"
chmod 755 "$PREFIX/add_to_github_path.sh"

for p in \
  "$PREFIX/proot/bin" \
  "$PREFIX/cabal/bin" \
  "$PREFIX/wizer/bin" \
  "$PREFIX/wasmer/bin" \
  "$PREFIX/wasmedge/bin" \
  "$PREFIX/wasmtime/bin" \
  "$PREFIX/wabt/bin" \
  "$PREFIX/binaryen/bin" \
  "$PREFIX/deno/bin" \
  "$PREFIX/wasi-sdk/bin"
do
  echo "export PATH=$p:\$PATH" >> "$PREFIX/env"
  echo "echo $p >> \$GITHUB_PATH" >> "$PREFIX/add_to_github_path.sh"
done

for e in \
  "AR=$PREFIX/wasi-sdk/bin/llvm-ar" \
  "CC=$PREFIX/wasi-sdk/bin/clang" \
  "CC_FOR_BUILD=cc" \
  "CXX=$PREFIX/wasi-sdk/bin/clang++" \
  "LD=$PREFIX/wasi-sdk/bin/wasm-ld" \
  "NM=$PREFIX/wasi-sdk/bin/llvm-nm" \
  "OBJCOPY=$PREFIX/wasi-sdk/bin/llvm-objcopy" \
  "OBJDUMP=$PREFIX/wasi-sdk/bin/llvm-objdump" \
  "RANLIB=$PREFIX/wasi-sdk/bin/llvm-ranlib" \
  "SIZE=$PREFIX/wasi-sdk/bin/llvm-size" \
  "STRINGS=$PREFIX/wasi-sdk/bin/llvm-strings" \
  "STRIP=$PREFIX/wasi-sdk/bin/llvm-strip"
do
  echo "export $e" >> "$PREFIX/env"
  echo "echo $e >> \$GITHUB_PATH" >> "$PREFIX/add_to_github_path.sh"
done

popd

echo "Everything set up in $PREFIX."
echo "Run 'source $PREFIX/env' to add tools to your PATH."
