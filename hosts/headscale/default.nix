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
  };
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  networking.firewall.allowedTCPPorts = [ 22 ];
  networking.firewall.allowedUDPPorts = [ 41641 ];

  system.stateVersion = "25.05";
}
