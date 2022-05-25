# `ghc-wasm32-wasi`

This repo provides convenient methods of using x86_64-linux binary
artifacts of our GHC wasm32-wasi port.

## As a nix flake

The default output(`ghc-wasm32-wasi`) is what you're looking for:

```sh
$ nix shell
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
Call /home/runner/.ghc-wasm32-wasi/ghc-wasm32-wasi-gmp/bin/wasm32-wasi-ghc or /home/runner/.ghc-wasm32-wasi/ghc-wasm32-wasi-native/bin/wasm32-wasi-ghc to get started.
```

Set `PREFIX` environment variable to customize where to set up things.
The script requires `curl` and `unzip` to run.

Note that `setup.sh` is not standalone, it calls auto-generated
scripts in `autogen/`, and you need to call it at the root directory
of this repo's checkout. Set `PREFIX`
