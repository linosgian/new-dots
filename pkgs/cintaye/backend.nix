{ pkgs, lib, ... }:
pkgs.buildGoModule {
  pname = "cintaye";
  version = "0.0.1";

  src = ./backend;

  # Run `nix build` once with lib.fakeHash, then replace with the printed hash.
  vendorHash = "sha256-+iwDqf79jaEJ+KP5QeBv9BDNH8x5yXVXK/Fc5w2uLxk=";

  meta = with lib; {
    description = "Cintaye recipe keeping app — Go backend";
    license = licenses.mit;
    maintainers = [ ];
  };
}
