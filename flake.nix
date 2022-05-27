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
        ghc-wasm32-wasi =
          pkgs.callPackage pkgs/ghc-wasm32-wasi.nix { inherit wasi-sdk; };
        wasm32-wasi-cabal = pkgs.callPackage pkgs/wasm32-wasi-cabal.nix {
          inherit cabal ghc-wasm32-wasi;
        };
        qemu-system-wasm32 =
          pkgs.callPackage pkgs/qemu-system-wasm32.nix { inherit wasmtime; };
        wabt = pkgs.callPackage pkgs/wabt.nix { };
      in
      {
        packages = {
          inherit pkgs binaryen cabal wasi-sdk wasmtime wasmtime-run
            ghc-wasm32-wasi wasm32-wasi-cabal qemu-system-wasm32 wabt;
          default = ghc-wasm32-wasi;
        };
        apps = {
          default = {
            type = "app";
            program = "${ghc-wasm32-wasi}/bin/wasm32-wasi-ghc";
          };
        };
      });
}
