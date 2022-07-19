{ lib, stdenv, cmake, fetchFromGitHub, libuv, substituteAll, }:
stdenv.mkDerivation rec {
  pname = "wasm3";
  version = "0.5.0";

  src = fetchFromGitHub {
    owner = "wasm3";
    repo = "wasm3";
    rev = "9dcfce271c2fac86823725fc9ec0f75309d820e4";
    hash =
      "sha512-Vf4qp7yOo1CQbI5Jdkw2mYXsCWg+5RmIVw0ulN2JJk8L6UOgMX2i9CauWutPlWTg3byAMM7Itnz4cqNLKHrAmQ==";
  };

  uvwasi_src = fetchFromGitHub {
    owner = "nodejs";
    repo = "uvwasi";
    rev = "f92bdd8d29ac43116ad6d18a41881b25c16600ff";
    hash =
      "sha512-2AnGUm8XgI1zbJGmyOExrWCX04K6lBLsbK+FLDWimSK9S+YyYwbxLCYHu1dvqHcVUjLpg3eK8iE3dAwB15dFmA==";
    postFetch = ''
      pushd $out
      patch -p1 < ${./uvwasi.diff}
      popd
    '';
  };

  patches = [ ./wasm3.diff ];

  postPatch = ''
    substituteAllInPlace CMakeLists.txt
  '';

  nativeBuildInputs = [ cmake ];

  buildInputs = [ libuv ];

  cmakeFlags = [ "-DBUILD_WASI=uvwasi" ];

  installPhase = ''
    install -Dm755 wasm3 -t $out/bin
  '';

  strictDeps = true;
}
