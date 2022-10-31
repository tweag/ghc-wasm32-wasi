{ autoPatchelfHook, ncurses, stdenv, stdenvNoCC, zlib, }:
let
  common-src = builtins.fromJSON (builtins.readFile ../autogen.json);
  wasi-sdk-src = builtins.fetchTarball common-src.wasi-sdk;
  libffi-wasm32-src = builtins.fetchTarball common-src.libffi-wasm32;
in
stdenvNoCC.mkDerivation {
  name = "wasi-sdk";
  dontUnpack = true;
  buildInputs = [ ncurses stdenv.cc.cc.lib zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir $out
    tar xzf ${wasi-sdk-src} --strip-components=1 -C $out

    patchShebangs $out
    autoPatchelf $out/bin

    cp -a ${libffi-wasm32-src}/include/. $out/share/wasi-sysroot/include
    cp -a ${libffi-wasm32-src}/lib/. $out/share/wasi-sysroot/lib/wasm32-wasi
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    pushd "$(mktemp -d)"
    echo '#include <stdio.h>' >> test.c
    echo 'int main(void) { printf("test"); }' >> test.c
    $out/bin/clang test.c -lffi -o test.wasm
    popd
  '';
  dontFixup = true;
  strictDeps = true;
}
