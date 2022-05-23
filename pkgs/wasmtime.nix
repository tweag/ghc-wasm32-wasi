{ autoPatchelfHook, callPackage, stdenvNoCC, }:
let wasmtime-src = callPackage ../autogen/wasmtime.nix { };
in
stdenvNoCC.mkDerivation {
  name = "wasmtime";
  nativeBuildInputs = [ autoPatchelfHook ];
  dontUnpack = true;
  installPhase = ''
    for f in ${wasmtime-src}/*.tar.xz; do
      tar xJf $f --strip-components=1
    done
    mkdir -p $out/bin
    install -Dm755 -t $out/bin wasmtime
  '';
  strictDeps = true;
}
