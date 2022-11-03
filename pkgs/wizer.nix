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
    tar -xJf ${src} -C $out/bin --strip-components=1 --wildcards '*/wizer'
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wizer --version
  '';
  strictDeps = true;
}
