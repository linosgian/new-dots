{
  config,
  pkgs,
  lib,
  ...
}:
pkgs.buildGoModule {
  pname = "nostos";
  version = "0.0.1";

  # Point to your app's source directory
  src = ./src;

  # You'll need to generate this - see instructions below
  vendorHash = null;
  # Or use vendorHash = null; if you're not using vendored dependencies

  # Optional: specify the main package path if not at root
  # subPackages = [ "cmd/myapp" ];

  meta = with lib; {
    description = "";
    homepage = "https://github.com/linosgian/nostos";
    license = licenses.mit;
    maintainers = [ ];
  };
}
