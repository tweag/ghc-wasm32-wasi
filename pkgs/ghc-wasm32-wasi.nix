{ autoPatchelfHook, callPackage, gmp, stdenvNoCC, wasi-sdk, }:
let ghc-wasm32-wasi-src = callPackage ../autogen/ghc-wasm32-wasi.nix { };
in
stdenvNoCC.mkDerivation {
  name = "ghc-wasm32-wasi";

  buildInputs = [ gmp ];
  nativeBuildInputs = [ autoPatchelfHook ];

  unpackPhase = ''
    cp -r ${ghc-wasm32-wasi-src} $out
    chmod -R u+w $out
    cd $out
  '';

  preConfigure = ''
    patchShebangs .
    autoPatchelf .

    configureFlagsArray+=(
      AR=${wasi-sdk}/bin/llvm-ar
      CC=${wasi-sdk}/bin/clang
      CXX=${wasi-sdk}/bin/clang++
      LD=${wasi-sdk}/bin/wasm-ld
      RANLIB=${wasi-sdk}/bin/llvm-ranlib
      STRIP=${wasi-sdk}/bin/llvm-strip
      CONF_CC_OPTS_STAGE2="-O3 -mmutable-globals -mnontrapping-fptoint -mreference-types -msign-ext"
      CONF_CXX_OPTS_STAGE2="-fno-exceptions -O3 -mmutable-globals -mnontrapping-fptoint -mreference-types -msign-ext"
      CONF_GCC_LINKER_OPTS_STAGE2="-Wl,--error-limit=0,--growable-table,--stack-first -Wno-unused-command-line-argument"
      --host=x86_64-linux
      --target=wasm32-wasi
    )
  '';

  buildPhase = ''
    make lib/settings
    ./bin/wasm32-wasi-ghc-pkg recache
  '';

  dontInstall = true;

  dontFixup = true;

  strictDeps = true;
}
