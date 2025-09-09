{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    hardware.url = "github:nixos/nixos-hardware";

    openwrt-imagebuilder.url = "github:astro/nix-openwrt-imagebuilder";
    home-manager.url = "github:nix-community/home-manager/release-25.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    nixvirt = {
      url = "https://flakehub.com/f/AshleyYakeley/NixVirt/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
  outputs =
    { self
    , nixpkgs
    , hardware
    , home-manager
    , openwrt-imagebuilder
    , disko
    , nixvirt
    , unstable
    , nixpkgs-master
    , sops-nix
    , ...
    }@inputs:
    let
      unstablePkgs = import unstable {
        system = "x86_64-linux"; # Adjust your system architecture
        config.allowUnfree = true; # Allow unfree packages in unstable channel
      };
      masterPkgs = import nixpkgs-master {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };
    in
    rec {

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
      nixosConfigurations = {
        okeanos = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/okeanos
            sops-nix.nixosModules.sops
          ];
        };
        cine = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/cine
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
          specialArgs = { inherit self unstablePkgs;  };
          system = "x86_64-linux";
          modules = [
            ./hosts/x1
            hardware.nixosModules.lenovo-thinkpad-x1-7th-gen
            home-manager.nixosModules.home-manager
          ];
        };
        desktop = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./hosts/desktop
            home-manager.nixosModules.home-manager
          ];
          specialArgs = { inherit self masterPkgs; };
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
            # "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
            ./hosts/sfiri
            sops-nix.nixosModules.sops
            {
              # sdImage.compressImage = false;
              nixpkgs.hostPlatform = "aarch64-linux";
            }
          ];
        };

        ntoulapa = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit self unstable unstablePkgs nixvirt; };
          modules = [
            disko.nixosModules.disko
            ./hosts/ntoulapa
            sops-nix.nixosModules.sops
            nixvirt.nixosModules.default
          ];
        };
      };

      images.sfiri = nixosConfigurations.sfiri.config.system.build.sdImage;

      packages.x86_64-linux = {
        newrouter =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            lib = nixpkgs.lib;
            mkPackageEntry = filename: {
              filename = filename;
              file = builtins.path {
                path = ./pkgs/prebuilt-openwrt/${filename};
                name = filename;
              };
              depends = [];
              provides = null;
              type = "real";
            };

            localPackages = 
              let
                ipkFiles = lib.filter (lib.hasSuffix ".ipk") 
                  (builtins.attrNames (builtins.readDir ./pkgs/prebuilt-openwrt));

                toPackageAttr = filename: {
                  name = lib.removeSuffix ".ipk" filename;
                  value = mkPackageEntry filename;
                };
              in
              builtins.listToAttrs (map toPackageAttr ipkFiles);


            profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; release = "24.10.2"; };
            config = profiles.identifyProfile "asus_tuf-ax4200" // {
              disabledServices = [ "dnsmasq" ];
              extraPackages = localPackages;
              packages = [
                "-odhcpd-ipv6only"
                "odhcpd"
                "tcpdump"
                "dnsmasq"
                "bind-host"
                "bind-dig"
                "coreutils"
                "curl"
                "https-dns-proxy"
                "ddns-scripts-digitalocean"
                "file"
                "luci-app-package-manager"
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
                "lua-cjson"
                "prometheus-node-exporter-lua"
                "prometheus-node-exporter-lua-openwrt"
                "prometheus-node-exporter-lua-wifi"
                "prometheus-node-exporter-lua-wifi_stations"
                "qosify"
                "ss"
                "tc-full"
                "smokeping_prober"
                "unbound_exporter"
                "prometheus-node-exporter-lua-sqm"
              ];
              files = pkgs.runCommand "image-files" {} ''
                mkdir -p $out/etc/uci-defaults
                  cat > $out/etc/uci-defaults/99-custom <<EOF
                  sed -i '/\s*devices = {{ fw4\.set(flowtable_devices, true) }};/s/{{.*}}/{ "eth1", "lan1", "lan2", "lan3", "lan4", "phy0-ap0", "phy0-ap1", "phy1-ap0", "phy1-ap1" }/' /usr/share/firewall4/templates/ruleset.uc
                  EOF
              '';
            };
          in
          openwrt-imagebuilder.lib.build config;
        oldrouter =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; release = "24.10.2"; };

            config = profiles.identifyProfile "xiaomi_redmi-router-ax6s" // {
              disabledServices = [ "dnsmasq" ];
              packages = [
                "-odhcpd-ipv6only"
                "odhcpd"
                "tcpdump"
                "dnsmasq"
                "bind-host"
                "bind-dig"
                "coreutils"
                "curl"
                "https-dns-proxy"
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
                "lua-cjson"
                "prometheus-node-exporter-lua"
                "prometheus-node-exporter-lua-sqm"
                "prometheus-node-exporter-lua-openwrt"
                "prometheus-node-exporter-lua-wifi"
                "prometheus-node-exporter-lua-wifi_stations"
                "qosify"
                "ss"
                "tc-full"
                "unbound_exporter"
                "smokeping_prober"
              ];
              files = pkgs.runCommand "image-files" { } ''
                mkdir -p $out/etc/uci-defaults
                  cat > $out/etc/uci-defaults/99-custom <<EOF
                  sed -i '/\s*devices = {{ fw4\.set(flowtable_devices, true) }};/s/{{.*}}/{ "eth1", "lan1", "lan2", "lan3", "lan4", "phy0-ap0", "phy0-ap1", "phy1-ap0", "phy1-ap1" }/' /usr/share/firewall4/templates/ruleset.uc
                  EOF
              '';
            };
          in
          openwrt-imagebuilder.lib.build config;
        ap =
          let
            pkgs = nixpkgs.legacyPackages.x86_64-linux;

            profiles = openwrt-imagebuilder.lib.profiles { inherit pkgs; release = "24.10.0"; };
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
