{ cabal, ghc-wasm32-wasi, writeShellScriptBin, }:
writeShellScriptBin "wasm32-wasi-cabal" ''
  exec ${cabal}/bin/cabal \
    --with-compiler=${ghc-wasm32-wasi}/bin/wasm32-wasi-ghc \
    --with-hc-pkg=${ghc-wasm32-wasi}/bin/wasm32-wasi-ghc-pkg \
    --with-hsc2hs=${ghc-wasm32-wasi}/bin/wasm32-wasi-hsc2hs \
    ''${1+"$@"}
''
