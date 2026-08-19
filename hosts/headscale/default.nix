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
    ../../modules/strovilos
  ];
  networking.hostName = "headscale";

  sops = {
    defaultSopsFile = ../../secrets/headscale/secrets.yaml;
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  };

  services.tailscale = {
    enable = true;
  };
  boot.kernel.sysctl."net.ipv4.conf.all.forwarding" = true;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = true;
  networking.firewall.allowedTCPPorts = [
    22
    80
  ];
  networking.firewall.allowedUDPPorts = [ 41641 ];

  system.stateVersion = "25.05";
}
