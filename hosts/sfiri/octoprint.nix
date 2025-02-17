{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [ octoprint ];
  nixpkgs.overlays = [
    (self: super: {
      octoprint = super.octoprint.override {
        packageOverrides = pyself: pysuper: {
          octoprint-dashboard = pyself.buildPythonPackage rec {
            pname = "Dashboard";
            version = "1.19.12";
            src = self.fetchFromGitHub {
              owner = "j7126";
              repo = "OctoPrint-Dashboard";
              rev = "${version}";
              sha256 = "sha256-454/nAAFT2afr0GA+X6KgFOu1Zeey4CvLgw2bPE6aEc";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
          };
          octoprint-octoapp = pyself.buildPythonPackage rec {
            pname = "OctoApp";
            version = "2.1.6";
            src = self.fetchFromGitHub {
              owner = "crysxd";
              repo = "OctoApp-Plugin";
              rev = "${version}";
              sha256 = "sha256-wt4sopozcKKPxsxOMwGnq0bHX0Q7yV0MfWJ7UXvYN+4=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
          };
          octoprint-prettygcode = pyself.buildPythonPackage rec {
            pname = "PrettyGCode";
            version = "1.0.7";
            src = self.fetchFromGitHub {
              owner = "jneilliii";
              repo = "OctoPrint-PrusaSlicerThumbnails";
              rev = "${version}";
              sha256 = "sha256-waNCTjAZwdBfhHyJCG2La7KTnJ8MDVuX1JLetFB5bS4=";
            };
            propagatedBuildInputs = [ pysuper.octoprint ];
            doCheck = false;
          };
        };
      };
    })
  ];
  services.octoprint.enable = true;
  services.octoprint.plugins =
    plugins: with plugins; [
      printtimegenius
      octoprint-prettygcode
      octoprint-octoapp
      octoprint-dashboard
    ];
  services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      virtualHosts."sfiri.lgian.com" =  {
        useACMEHost = "sfiri.lgian.com";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://127.0.0.1:5000";
          proxyWebsockets = true; # needed if you need to use WebSocket
        };
      };
  };
  users.users.nginx.extraGroups = [ "acme" ];
  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.defaults.server = "https://acme-v02.api.letsencrypt.org/directory";
  security.acme.certs."sfiri.lgian.com" = {
    domain = "sfiri.lgian.com";
    dnsProvider = "digitalocean";
    dnsResolver = "ns2.digitalocean.com:53";
    dnsPropagationCheck = true;
    environmentFile = "${pkgs.writeText "do-creds" ''
      DO_AUTH_TOKEN=dop_v1_a70256ee032fc0bbaf2a37a68b72a6973914a6571911e27dec30952bf6aa22ff
      DO_PROPAGATION_TIMEOUT=600
      DO_POLLING_INTERVAL=60
    ''}";
  };

}
