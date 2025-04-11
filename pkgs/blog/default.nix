{ lib , pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "blog";
  version = "0.1";
 
  src = builtins.fetchGit {
    url = "https://github.com/linosgian/ehlo";
    ref = "tmp";
    rev = "e0b1c89beb64aec65ab34dba57a90f07909dbc75";
  };
 
  nativeBuildInputs = [ pkgs.hugo ];

  buildPhase = ''
    hugo --minify --destination=public/
  '';
  installPhase = ''
    mkdir -p $out
    cp -r public/* $out/
  '';
 
  meta = {
    description = "Hugo project for ${pname}";
  };
}
