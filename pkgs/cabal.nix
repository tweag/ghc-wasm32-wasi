{ autoPatchelfHook, callPackage, gmp, stdenvNoCC, zlib, }:
let cabal-src = callPackage ../autogen/cabal.nix { };
in
stdenvNoCC.mkDerivation {
  name = "cabal";
  buildInputs = [ gmp zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    tar xf ${cabal-src}/cabal-head.tar -C $out/bin
  '';
  strictDeps = true;
}
