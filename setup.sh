#!/usr/bin/env bash

set -euo pipefail

readonly BIGNUM_BACKEND="${BIGNUM_BACKEND:-gmp}"
readonly PREFIX="${PREFIX:-$HOME/.ghc-wasm32-wasi}"
readonly REPO=$PWD
readonly SKIP_GHC="${SKIP_GHC:-}"

rm -rf "$PREFIX"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

pushd "$workdir"

mkdir -p "$PREFIX/fake-wasm-opt/bin"
echo "#!/bin/sh" >> "$PREFIX/fake-wasm-opt/bin/wasm-opt"
chmod +x "$PREFIX/fake-wasm-opt/bin/wasm-opt"

"$REPO/autogen/wasi-sdk.sh" > dist-ubuntu-latest.zip
unzip dist-ubuntu-latest.zip
mkdir -p "$PREFIX/wasi-sdk"
tar xzf wasi-sdk-*.tar.gz --strip-components=1 -C "$PREFIX/wasi-sdk"

for p in clang clang++
do
  rm "$PREFIX/wasi-sdk/bin/$p"
  echo "#!/usr/bin/env bash" >> "$PREFIX/wasi-sdk/bin/$p"
  echo "PATH=$PREFIX/fake-wasm-opt/bin:\$PATH exec -a $PREFIX/wasi-sdk/bin/$p" "$PREFIX/wasi-sdk/bin/clang-14" '${1+"$@"}' >> "$PREFIX/wasi-sdk/bin/$p"
  chmod +x "$PREFIX/wasi-sdk/bin/$p"
done

"$REPO/autogen/libffi-wasm32.sh" > out.zip
unzip out.zip
cp include/*.h "$PREFIX/wasi-sdk/share/wasi-sysroot/include"
cp lib/*.a "$PREFIX/wasi-sdk/share/wasi-sysroot/lib/wasm32-wasi"

"$REPO/autogen/wasmtime.sh" > bins-x86_64-linux.zip
unzip bins-x86_64-linux.zip
mkdir -p "$PREFIX/wasmtime/bin"
tar xJf wasmtime-*-x86_64-linux.tar.xz --strip-components=1 -C "$PREFIX/wasmtime/bin" --wildcards '*/wasmtime'

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

echo "#!/bin/sh" >> "$PREFIX/add_to_github_path.sh"
chmod +x "$PREFIX/add_to_github_path.sh"

for p in \
  "$PREFIX/wabt/bin" \
  "$PREFIX/binaryen/bin" \
  "$PREFIX/wasmtime/bin" \
  "$PREFIX/wasmtime-run/bin" \
  "$PREFIX/wasi-sdk/bin" \
  "$PREFIX/ghc-wasm32-wasi/bin" \
  "$PREFIX/wasm32-wasi-cabal/bin"
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

"$REPO/autogen/binaryen.sh" > build-ubuntu-latest.zip
mkdir "$PREFIX/binaryen"
unzip build-ubuntu-latest.zip -d "$PREFIX/binaryen"
chmod +x "$PREFIX"/binaryen/bin/*

mkdir "$PREFIX/wabt"
curl -L https://github.com/WebAssembly/wabt/releases/download/1.0.29/wabt-1.0.29-ubuntu.tar.gz | tar xz --strip-components=1 -C "$PREFIX/wabt"

if [ -n "${SKIP_GHC}" ]
then
	exit
fi

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

"$REPO/autogen/cabal.sh" > cabal-Linux-8.10.7.zip
unzip cabal-Linux-8.10.7.zip
mkdir -p "$PREFIX/cabal/bin"
tar xf cabal-head.tar -C "$PREFIX/cabal/bin"

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

popd

echo "Everything set up in $PREFIX."
echo "Run 'source $PREFIX/env' to add tools to your PATH."
