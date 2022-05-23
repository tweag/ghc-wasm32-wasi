{ autoPatchelfHook, callPackage, libxml2, ncurses, stdenv, stdenvNoCC, }:
let
  wasi-sdk-src = callPackage ../autogen/wasi-sdk.nix { };
  libffi-wasm32-src = callPackage ../autogen/libffi-wasm32.nix { };
in
stdenvNoCC.mkDerivation {
  name = "wasi-sdk";

  buildInputs = [ libxml2 ncurses stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook ];

  dontUnpack = true;

  installPhase = ''
    mkdir $out
    tar xzf ${wasi-sdk-src}/wasi-sdk-*.tar.gz --strip-components=1 -C $out
    patchShebangs $out
    autoPatchelf $out/bin

    cp ${libffi-wasm32-src}/include/*.h $out/share/wasi-sysroot/include
    cp ${libffi-wasm32-src}/lib/*.a $out/share/wasi-sysroot/lib/wasm32-wasi
  '';

  dontFixup = true;

  strictDeps = true;
}
