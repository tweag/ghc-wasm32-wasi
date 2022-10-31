{ autoPatchelfHook, ncurses, stdenv, stdenvNoCC, zlib, }:
let
  src = builtins.fetchTarball
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wasmedge);
in
stdenvNoCC.mkDerivation {
  name = "wasmedge";
  dontUnpack = true;
  buildInputs = [ ncurses stdenv.cc.cc.lib zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir $out
    cp -a ${src}/bin ${src}/lib $out
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasmedge --version
  '';
  strictDeps = true;
}
