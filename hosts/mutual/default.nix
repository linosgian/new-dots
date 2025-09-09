{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  services.qemuGuest.enable = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1" # enables libvirt console
  ];
  boot.growPartition = true;

  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 10240;
    format = "qcow2";
    partitionTableType = "hybrid";
  };

  networking.nameservers = [ "1.1.1.1" ];

  networking.hostName = "mutual";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.interfaces."enp0s3".allowedTCPPorts = [
    22
    9000
    9999
  ];
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [
    9000
    9999
  ];

  services.prometheus.exporters.blackbox = {
    enable = true;
    port = 9000;

    configFile = pkgs.writeText "config.yaml" ''
      modules:
        http_2xx:
          prober: http
          timeout: 5s
          http:
            valid_http_versions: ["HTTP/1.1", "HTTP/2.0"]
            valid_status_codes: []  # Defaults to 2xx
            method: GET
            no_follow_redirects: false
            fail_if_ssl: false
    '';
  };

  services.tailscale.enable = true;

  services.minio = {
    enable = true;
    listenAddress = ":9999";
    dataDir = [ "/data" ];
  };

  environment.systemPackages = with pkgs; [
    minio-client
  ];

  system.stateVersion = "25.05";
}
