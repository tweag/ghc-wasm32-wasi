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
        wasi-sdk = pkgs.callPackage pkgs/wasi-sdk.nix { };
        wasmtime = pkgs.callPackage pkgs/wasmtime.nix { };
        ghc-wasm32-wasi =
          pkgs.callPackage pkgs/ghc-wasm32-wasi.nix { inherit wasi-sdk; };
      in
      {
        packages = {
          inherit pkgs wasi-sdk wasmtime ghc-wasm32-wasi;
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
