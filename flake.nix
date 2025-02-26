{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    hardware.url = "github:nixos/nixos-hardware";

    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    colmena.url = "github:zhaofengli/colmena";

    microvm.url = "github:astro/microvm.nix";
    microvm.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    hardware,
    home-manager,
    openwrt-imagebuilder,
    microvm,
    colmena,
    ...
  }@inputs:
  rec {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;

    colmena = {
      meta = {
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };
    };
    nixosConfigurations = {
      my-microvm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          microvm.nixosModules.microvm
          ./blueprints/server.nix
          {
            networking.hostName = "foobar";
            microvm.hypervisor = "qemu";
          }
        ];
      };
      test-nix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/test-nix
        ];
      };
      mutual = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/mutual
        ];
      };
      headscale = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/headscale
        ];
      };
      cflow = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/x1
          hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
          home-manager.nixosModules.home-manager
        ];
      };
      xps = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/xps
          hardware.nixosModules.dell-xps-15-9500
        ];
      };
      sfiri = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./hosts/sfiri
            {
              sdImage.compressImage = false;
              nixpkgs.hostPlatform = "aarch64-linux";
            }
        ];
      };
      connector = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/connector
        ];
      };

      ntoulapa = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/virtualisation/qemu-vm.nix"
          ./modules/nomad.nix
          ./modules/consul.nix
          ./hosts/ntoulapa
        ];
      };
    };

    images.sfiri = nixosConfigurations.sfiri.config.system.build.sdImage;

    packages.x86_64-linux = {
      mainrouter =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; release="23.05.5";};
          disabledServices = [ "dnsmasq" ];
          config = profiles.identifyProfile "xiaomi_redmi-router-ax6s" // {
            packages = [
              "tcpdump"
              "dnsmasq"
              "bind-host"
              "bind-dig"
              "coreutils"
              "curl"
              "ddns-scripts-digitalocean"
              "openssh-server"
              "openssh-sftp-server"
              "openssh-client"
              "ethtool-full"
              "htop"
              "ip-full"
              "iperf3"
              "jq"
              "python3"
              "irqbalance"
              "adblock"
              "luci-ssl"
              "acme-acmesh"
              "acme-acmesh-dnsapi"
              "zsh"
              "vim-fuller"
              "netcat"
              "unbound-control"
              "unbound-daemon"
              "lm-sensors"
              "prometheus-node-exporter-lua"
              "prometheus-node-exporter-lua-openwrt"
              "prometheus-node-exporter-lua-wifi"
              "prometheus-node-exporter-lua-wifi_stations"
              "qosify"
              "ss"
              "tc-full"
            ];
            hackExtraPackages = [
              "smokeping_prober"
              "unbound_exporter"
              "prometheus-node-exporter-lua-sqm"
            ];
            files = pkgs.runCommand "image-files" {} ''
              mkdir -p $out/etc/uci-defaults
                cat > $out/etc/uci-defaults/99-custom <<EOF
                sed -i '/\s*devices = {{ fw4\.set(flowtable_devices, true) }};/s/{{.*}}/{ "lan1", "lan2", "lan3" }/' /usr/share/firewall4/templates/ruleset.uc
                EOF
            '';
          };
        in
        openwrt-imagebuilder.lib.build config;
      ap =
        let
          pkgs = nixpkgs.legacyPackages.x86_64-linux;

          profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; release="24.10.0";};
          config = profiles.identifyProfile "xiaomi_mi-router-4a-100m" // {
            packages = [
              "tcpdump"
              "dnsmasq"
              "openssh-server"
              "openssh-sftp-server"
              "htop"
              "luci-ssl"
              "mosquitto-ssl"
              "acme-acmesh"
              "acme-acmesh-dnsapi"
              "zsh"
              "vim"
            ];
          };
        in
        openwrt-imagebuilder.lib.build config;
    };
  };
}
