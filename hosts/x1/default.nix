{config, pkgs, ...}:
{
  imports = [
    ../../blueprints/workstation.nix
    ../../blueprints/laptop.nix
    ./hardware-configuration.nix
  ];
  services.thinkfan = {
    enable = true;
    #sensor = "/sys/devices/virtual/thermal/thermal_zone0/temp";
    levels = [
      [ 0 0 55 ]
      [ "level auto" 53 87 ]
      [ "level full-speed" 85 95 ]
      [ "level disengaged" 93 32767 ]
    ];

  };
  services.irqbalance.enable = true;
  environment.systemPackages = with pkgs; [
    dig
    aws-vault
    awscli2
    python3
    k9s
    kubectl
    kubectx
    slack
  ];

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "192.168.10.28/32" ];
      #dns = [ "10.100.0.2" ];
      listenPort = 51820;
      privateKeyFile = "/etc/nixos/cf-privkey";

      peers = [
        {
          publicKey = "bqOVQlwuEu3mXx/k0rRoMF4csjnG54uFz8JuEf63xQA=";

          allowedIPs = [ "192.168.10.3/32" "192.168.10.0/24" "192.168.129.206/24" "192.168.129.206/24" "192.168.131.0/24" "192.168.130.214/24" "10.100.0.0/16" "10.250.0.0/16" "10.200.0.0/16" "10.1.0.0/16" ];
          endpoint = "cf-wg-eu-90544ccb5a9cb155.elb.eu-central-1.amazonaws.com:55442";
        }
      ];
    };
  };
  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = "127.0.0.1";
      bind-interfaces = true;
    };
    resolveLocalQueries = true;
    settings.server= [
      "/ec2.cfl/10.100.0.2"
      "/eks.cfl/10.100.0.2"
      "/937DE1F752050623115CE038A346EA0E.gr7.eu-central-1.eks.amazonaws.com/10.100.0.2"
    ];
  };
  system.stateVersion = "24.11";
}
