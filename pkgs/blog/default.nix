{ lib, pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "blog";
  version = "0.1";

  src = builtins.fetchGit {
    url = "https://github.com/linosgian/ehlo";
    ref = "tmp";
    rev = "1a760557b47eb9589769d46bfca7114f39f6e458";
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
