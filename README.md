# `ghc-wasm32-wasi`

This repo provides convenient methods of using x86_64-linux binary
artifacts of our GHC wasm32-wasi port.

## Getting started as a nix flake

The default output is a derivation that bundles all provided tools:

```sh
$ nix shell
$ wasm32-wasi-ghc --version
The Glorious Glasgow Haskell Compilation System, version 9.5.20220520
```

## As a shell script

For Ubuntu 20.04 and similar glibc-based distros:

```sh
$ ./setup.sh
...
Everything set up in /home/runner/.ghc-wasm32-wasi.
Run 'source /home/runner/.ghc-wasm32-wasi/env' to add tools to your PATH.
```

Set `PREFIX` environment variable to customize where to set up things.
Set `BIGNUM_BACKEND` to `gmp`/`native` to specify the `ghc-bignum`
backend. The script requires `curl` and `unzip` to run.

## Provided tools

- `wasi-sdk`
- `wasm32-wasi-ghc`
- `wasm32-wasi-cabal`: A `cabal` wrapper that automatically uses
  `wasm32-wasi-ghc`, and builds stuff in an isolated `cabal` store to
  avoid interfering with host `cabal`.
- `wasmtime`
- `wasmtime-run`
- `binaryen`
- `wabt`

## `wasmtime-run`

`wasmtime-run` requires `proot` to be installed (in the non-nix
version). It enables you to run ELF/wasm hybrid apps, using `wasmtime`
as the wasm execution engine, as long as the wasm file has set the
execution bit.

```
$ wasmtime-run ./some-wasm.wasm arg1 arg2
$ wasmtime-run wasm32-wasi-cabal run target
```

See this [blog
post](https://www.tweag.io/blog/2022-03-31-running-wasm-native-hybrid-code/)
for implementation details.
