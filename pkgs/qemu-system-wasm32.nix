{stdenv, wasmtime}: stdenv.mkDerivation {
  name = "qemu-system-wasm32";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    $CC \
      -DWASMTIME='"${wasmtime}/bin/wasmtime"' \
      -Wall \
      -Wextra \
      -O3 \
      -o $out/bin/qemu-system-wasm32 \
      ${../cbits/qemu-system-wasm32.c}
  '';

  strictDeps = true;
}
