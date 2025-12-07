{
  config,
  pkgs,
  lib,
  ...
}:
pkgs.buildGoModule {
  pname = "athinorama";
  version = "0.0.1";

  src = ./src;

  vendorHash = "sha256-dEXkbgyWv+KOpcnk4aHC/7h3SM0DUROf4OekqGm66T0=";

  meta = with lib; {
    description = "";
    homepage = "https://github.com/linosgian/athinorama";
    license = licenses.mit;
    maintainers = [ ];
  };
}
