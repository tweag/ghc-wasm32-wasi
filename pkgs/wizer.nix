{ autoPatchelfHook, stdenvNoCC, }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wizer);
in
stdenvNoCC.mkDerivation {
  name = "wizer";
  dontUnpack = true;
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 ${src} $out/bin/wizer
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wizer --version
  '';
  strictDeps = true;
}
