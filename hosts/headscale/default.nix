{
  config,
  pkgs,
  unstablePkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./hardware-configuration.nix
  ];
  networking.hostName = "headscale";

  services.tailscale = {
    enable = true;
    # NOTE: Remove this once https://github.com/NixOS/nixpkgs/issues/438765 is fixed on 25.05
    package = unstablePkgs.tailscale;
  };
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 41641 ];

  system.stateVersion = "25.05";
}
