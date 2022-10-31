{ autoPatchelfHook, stdenv, stdenvNoCC, }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wabt);
in
stdenvNoCC.mkDerivation {
  name = "wabt";
  dontUnpack = true;
  buildInputs = [ stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src}/bin/* $out/bin
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasm-objdump --version
  '';
  strictDeps = true;
}
