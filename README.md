# `ghc-wasm32-wasi`

This repo provides convenient methods of using x86_64-linux binary
artifacts of our GHC wasm32-wasi port.

## As a nix flake

The `ghc-wasm32-wasi` output is what you're looking for:

```sh
$ nix shell .#ghc-wasm32-wasi
$ wasm32-wasi-ghc --version
The Glorious Glasgow Haskell Compilation System, version 9.5.20220520
```

Each revision of this repo contains auto-generated fetchers that pin
to specific revisions of input binary artifacts. Run `autogen.mjs` to
bump artifact revisions when needed.

## As a shell script

For Ubuntu 20.04 and similar glibc-based distros:

```sh
$ ./setup.sh
...
Everything set up in /home/runner/.ghc-wasm32-wasi.
Call /home/runner/.ghc-wasm32-wasi/ghc/bin/wasm32-wasi-ghc to get started.
```
