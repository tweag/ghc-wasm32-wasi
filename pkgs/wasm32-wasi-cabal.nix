{ cabal, ghc-wasm32-wasi, writeShellScriptBin, }:
writeShellScriptBin "wasm32-wasi-cabal" ''
  export CABAL_DIR="''${CABAL_DIR:-$HOME/.ghc-wasm32-wasi/.cabal}"

  if [ ! -f "$CABAL_DIR/config" ]
  then
    mkdir -p "$CABAL_DIR"
    cp ${../cabal.config} "$CABAL_DIR/config"
    chmod u+w "$CABAL_DIR/config"
  fi

  exec ${cabal}/bin/cabal \
    --with-compiler=${ghc-wasm32-wasi}/bin/wasm32-wasi-ghc \
    --with-hc-pkg=${ghc-wasm32-wasi}/bin/wasm32-wasi-ghc-pkg \
    --with-hsc2hs=${ghc-wasm32-wasi}/bin/wasm32-wasi-hsc2hs \
    ''${1+"$@"}
''
