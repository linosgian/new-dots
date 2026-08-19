{ pkgs, lib, ... }:
pkgs.buildNpmPackage {
  pname = "cintaye-frontend";
  version = "0.0.1";

  src = ./frontend;

  # Update this by building once with lib.fakeHash, then substituting the
  # hash printed in the error.
  npmDepsHash = "sha256-AXKFhV2d+ekL8khxZCFK580p2i0eb16D234rDXNIUnw=";

  # npm run build → tsc -b && vite build → dist/
  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r dist/. $out
    runHook postInstall
  '';
}
