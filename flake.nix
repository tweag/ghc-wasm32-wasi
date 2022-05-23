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
      in
      { packages = { inherit pkgs wasi-sdk; }; });
}
