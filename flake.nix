{
  inputs = {
    haskell-nix = {
      type = "github";
      owner = "input-output-hk";
      repo = "haskell.nix";
    };
  };

  outputs = { self, haskell-nix, }:
    haskell-nix.inputs.flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import haskell-nix.inputs.nixpkgs-unstable {
          inherit system;
          config = haskell-nix.config;
          overlays = [ haskell-nix.overlay ];
        };
        all = pkgs.symlinkJoin {
          name = "ghc-wasm32-wasi-tools";
          paths = [
            wasi-sdk
            deno
            binaryen
            wabt
            wasmtime
            wasmedge
            wasmer
            wizer
            cabal
            proot
          ];
        };
        wasi-sdk = pkgs.callPackage ./pkgs/wasi-sdk.nix { };
        deno = pkgs.callPackage ./pkgs/deno.nix { };
        binaryen = pkgs.callPackage ./pkgs/binaryen.nix { };
        wabt = pkgs.callPackage ./pkgs/wabt.nix { };
        wasmtime = pkgs.callPackage ./pkgs/wasmtime.nix { };
        wasmedge = pkgs.callPackage ./pkgs/wasmedge.nix { };
        wasmer = pkgs.callPackage ./pkgs/wasmer.nix { };
        wizer = pkgs.callPackage ./pkgs/wizer.nix { };
        cabal = pkgs.callPackage ./pkgs/cabal.nix { };
        proot = pkgs.callPackage ./pkgs/proot.nix { };
      in
      {
        packages = {
          inherit all wasi-sdk deno binaryen wabt wasmtime wasmedge wasmer wizer
            cabal proot;
        };
      });
}
