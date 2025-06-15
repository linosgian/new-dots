{ lib, pkgs }:
pkgs.stdenv.mkDerivation rec {
  pname = "blog";
  version = "0.1";

  src = builtins.fetchGit {
    url = "https://github.com/linosgian/ehlo";
    ref = "tmp";
    rev = "fb96e33c67800e6fe91fae5e16c6843c70739572";
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
