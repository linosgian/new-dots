{ pkgs }:

pkgs.stdenv.mkDerivation {
  pname = "sway-scripts";
  version = "1.1";
  src = ./scripts;

  installPhase = ''
    mkdir -p $out/bin
    cp scratch.sh screenshot.sh switcher.sh volcontrol.sh $out/bin/
    chmod +x $out/bin/*

    mkdir -p $out/share/sounds
    cp volume-up.oga $out/share/sounds/

    chmod +w $out/bin/volcontrol.sh
    substituteInPlace $out/bin/volcontrol.sh \
      --replace "@sound_file@" "$out/share/sounds/volume-up.oga"
  '';

  meta = {
    description = "Collection of helper scripts for my Sway setup";
    license = pkgs.lib.licenses.mit;
    platforms = pkgs.lib.platforms.linux;
  };
}
