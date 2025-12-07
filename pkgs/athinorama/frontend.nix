{
  config,
  pkgs,
  lib,
  ...
}:
pkgs.stdenv.mkDerivation {
  pname = "athinorama-frontend";
  version = "0.1.0";
  src = ./web;
  installPhase = ''
    mkdir -p $out
    cp -r * $out/
  '';
}
