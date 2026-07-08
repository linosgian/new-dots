{ pkgs, lib, ... }:
pkgs.buildNpmPackage {
  pname = "cintaye-frontend";
  version = "0.0.1";

  src = ./frontend;

  # Update this by building once with lib.fakeHash, then substituting the
  # hash printed in the error.
  npmDepsHash = "sha256-INesVZlda8tTgMzUc2M2yLbi6OoqZz3MAPyDu8rCppo=";

  # npm run build → tsc -b && vite build → dist/
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/. $out
    runHook postInstall
  '';
}
