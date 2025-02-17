{ pkgs, lib, config, ... }:
let
  # Tailscale service template
  serviceTemplate = name: port:
    let
      stateDir = "/var/lib/tailscale-${name}";
    in {
      "tailscaled-${name}" = {
        description = "Tailscale Service Instance ${name}";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.tailscale}/bin/tailscaled --port ${toString port} --socket ${stateDir}/tailscale.socket --tun=tailscale-${name} --state ${stateDir}/tailscaled.state --statedir ${stateDir}/";
          Restart = "always";
        };
        path = [ pkgs.tailscale ];
      };
    };
  # Services list
  services = [
    { name = "self"; tailscaled_port = 8080; cidr = "198.18.0.0/24"; }
    { name = "com"; tailscaled_port = 8081; cidr = "198.18.4.0/24"; }
  ];

  tailscaleServices = lib.foldl'
    lib.recursiveUpdate
    {}
    (map (service: serviceTemplate service.name service.tailscaled_port) services);
in
{
  # Environment configurations
  environment = {
    systemPackages = with pkgs; [ tailscale ];
  };

  # Flatten and merge systemd services
  systemd.services = tailscaleServices;
  services.tailscale.useRoutingFeatures = "server";
  services.tailscale.enable = true;
}

