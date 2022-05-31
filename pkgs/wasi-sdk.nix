{ autoPatchelfHook
, callPackage
, libxml2
, makeWrapper
, ncurses
, stdenv
, stdenvNoCC
, writeShellScriptBin
,
}:
let
  wasi-sdk-src = callPackage ../autogen/wasi-sdk.nix { };
  libffi-wasm32-src = callPackage ../autogen/libffi-wasm32.nix { };
  fake-wasm-opt = writeShellScriptBin "wasm-opt" "";
in
stdenvNoCC.mkDerivation {
  name = "wasi-sdk";

  buildInputs = [ libxml2 ncurses stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];

  dontUnpack = true;

  installPhase = ''
    mkdir $out
    tar xzf ${wasi-sdk-src}/wasi-sdk-*.tar.gz --strip-components=1 -C $out

    patchShebangs $out
    autoPatchelf $out/bin

    for p in clang clang++
    do
      rm $out/bin/$p
      makeWrapper \
        $out/bin/clang-15 \
        $out/bin/$p \
        --argv0 $out/bin/$p \
        --prefix PATH : ${fake-wasm-opt}/bin
    done

    cp ${libffi-wasm32-src}/include/*.h $out/share/wasi-sysroot/include
    cp ${libffi-wasm32-src}/lib/*.a $out/share/wasi-sysroot/lib/wasm32-wasi
  '';

  dontFixup = true;

  strictDeps = true;
}
