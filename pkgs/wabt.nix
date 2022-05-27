{ autoPatchelfHook, stdenv, stdenvNoCC, }:
let
  src = builtins.fetchTarball {
    url =
      "https://github.com/WebAssembly/wabt/releases/download/1.0.29/wabt-1.0.29-ubuntu.tar.gz";
    sha256 = "sha256-JVLUPuB/oNwh7LW6ucTC1hd+eTZehCUkv1wqyLCR94o=";
  };
in
stdenvNoCC.mkDerivation {
  name = "wabt";
  buildInputs = [ stdenv.cc.cc.lib ];
  nativeBuildInputs = [ autoPatchelfHook ];
  dontUnpack = true;
  installPhase = ''
    cp -r ${src} $out
  '';
  strictDeps = true;
}
