{ autoPatchelfHook, callPackage, stdenv, stdenvNoCC, }:
let binaryen-src = callPackage ../autogen/binaryen.nix { };
in
stdenvNoCC.mkDerivation {
  name = "binaryen";
  buildInputs = [ stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  dontUnpack = true;
  installPhase = ''
    cp -r ${binaryen-src} $out
    chmod +x $out/bin/*
  '';
  strictDeps = true;
}
