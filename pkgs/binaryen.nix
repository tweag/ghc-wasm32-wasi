{ autoPatchelfHook, stdenvNoCC, }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).binaryen);
in
stdenvNoCC.mkDerivation {
  name = "binaryen";
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src}/bin/* $out/bin
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasm-opt --version
  '';
  strictDeps = true;
}
