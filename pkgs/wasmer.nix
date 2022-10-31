{ autoPatchelfHook, ncurses5, stdenv, stdenvNoCC, zlib, }:
let
  src = builtins.fetchurl
    ((builtins.fromJSON (builtins.readFile ../autogen.json)).wasmer);
in
stdenvNoCC.mkDerivation {
  name = "wasmer";
  dontUnpack = true;
  buildInputs = [ ncurses5 stdenv.cc.cc.lib zlib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  installPhase = ''
    mkdir $out
    tar xzf ${src} -C $out --wildcards 'bin/*'
  '';
  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/wasmer --version
  '';
  strictDeps = true;
}
