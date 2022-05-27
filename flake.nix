{
  description = "A very basic flake";

  inputs = {
    flake-utils = {
      type = "github";
      owner = "numtide";
      repo = "flake-utils";
    };

    nixpkgs = {
      type = "github";
      owner = "NixOS";
      repo = "nixpkgs";
      ref = "nixpkgs-unstable";
    };
  };

  outputs = { self, flake-utils, nixpkgs, }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { contentAddressedByDefault = false; };
        };
        binaryen = pkgs.callPackage pkgs/binaryen.nix { };
        cabal = pkgs.callPackage pkgs/cabal.nix { };
        wasi-sdk = pkgs.callPackage pkgs/wasi-sdk.nix { };
        wasmtime = pkgs.callPackage pkgs/wasmtime.nix { };
        wasmtime-run = pkgs.callPackage pkgs/wasmtime-run.nix {
          inherit qemu-system-wasm32;
        };
        ghc-wasm32-wasi = ghc-wasm32-wasi-gmp;
        ghc-wasm32-wasi-gmp = pkgs.callPackage pkgs/ghc-wasm32-wasi.nix {
          inherit wasi-sdk;
          bignumBackend = "gmp";
        };
        ghc-wasm32-wasi-native = pkgs.callPackage pkgs/ghc-wasm32-wasi.nix {
          inherit wasi-sdk;
          bignumBackend = "native";
        };
        wasm32-wasi-cabal = wasm32-wasi-cabal-gmp;
        wasm32-wasi-cabal-gmp = pkgs.callPackage pkgs/wasm32-wasi-cabal.nix {
          inherit cabal;
          ghc-wasm32-wasi = ghc-wasm32-wasi-gmp;
        };
        wasm32-wasi-cabal-native = pkgs.callPackage pkgs/wasm32-wasi-cabal.nix {
          inherit cabal;
          ghc-wasm32-wasi = ghc-wasm32-wasi-native;
        };
        qemu-system-wasm32 =
          pkgs.callPackage pkgs/qemu-system-wasm32.nix { inherit wasmtime; };
        wabt = pkgs.callPackage pkgs/wabt.nix { };
        combined = combined-gmp;
        combined-gmp = pkgs.symlinkJoin {
          name = "ghc-wasm32-wasi-combined-gmp";
          paths = [
            ghc-wasm32-wasi-gmp
            wasm32-wasi-cabal-gmp
            wasi-sdk
            binaryen
            wabt
            wasmtime
            wasmtime-run
          ];
        };
        combined-native = pkgs.symlinkJoin {
          name = "ghc-wasm32-wasi-combined-native";
          paths = [
            ghc-wasm32-wasi-native
            wasm32-wasi-cabal-native
            wasi-sdk
            binaryen
            wabt
            wasmtime
            wasmtime-run
          ];
        };
      in
      {
        packages = {
          inherit pkgs binaryen cabal wasi-sdk wasmtime wasmtime-run
            ghc-wasm32-wasi ghc-wasm32-wasi-gmp ghc-wasm32-wasi-native
            wasm32-wasi-cabal wasm32-wasi-cabal-gmp wasm32-wasi-cabal-native
            qemu-system-wasm32 wabt combined combined-gmp combined-native;
          default = combined;
        };
        apps = {
          default = {
            type = "app";
            program = "${combined}/bin/wasm32-wasi-ghc";
          };
        };
      });
}
