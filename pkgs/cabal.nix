{ autoPatchelfHook, gmp, stdenvNoCC, zlib, }:
let
  src = builtins.fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).cabal);
in
stdenvNoCC.mkDerivation {
  name = "cabal";
  dontUnpack = true;
  buildInputs = [ gmp zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir -p $out/bin
    tar xJf ${src} -C $out/bin 'cabal'
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/cabal --version
  '';
  strictDeps = true;
}
